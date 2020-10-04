
#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	enviarcorreos.pl
# DESCRIPTION:	envia correos periodicos con los listados de equipos y dispositivos
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0


use strict;
#use warnings;
use DBI;
use Excel::Writer::XLSX;
use Time::Local;
use Net::Netmask;
use MIME::Base64;
use Mail::Sender;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %tipestpc=();
my %nproveedores=();

my $dirficheros = "/tmp";
$dirficheros = "c:/xampp/cgi-bin/inventario" if ( $^O eq "MSWin32" );
my $nomlista1 = "Listado_equipos";
my $nomlista2 = "Listado_dispositivos";
my $fsalida1;
my $fsalida2;

# datos correo
my $servidorcorreo = "191.0.0.12";
my $remitente = 'InventarioOCS@laboratorio.com';
my $ldestinatarios = 'ssau@laboratorio.com';
my $ldestocultos = '';
my $asunto = 'Llistat setmanal (Equips/Dispositius)';
my $mensaje = 'Llistat setmanal (Equips/Dispositius)';
my $usucorreo = '';
my $passwordcorreo = '';


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

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# listado equipos
listaequipos();

# listado dispositivos
listadispositivos();

# inicializar correo
my $rparcorreos = { smtp => $servidorcorreo, from => $remitente, to => $ldestinatarios, TLS_allowed => 0 };
$rparcorreos->{bcc} = "$ldestocultos" if $ldestocultos;
if ( $usucorreo ) {
	$rparcorreos->{auth} = 'PLAIN';
	$rparcorreos->{authid} = $usucorreo;
	$rparcorreos->{authpwd} = $passwordcorreo;
}
my $sender = new Mail::Sender $rparcorreos;
die "Error al crear el objeto correo : $Mail::Sender::Error\n" unless ref $sender;


goto p1;
if (ref $sender->OpenMultipart({
	subject => $asunto,
	boundary => 'boundary-test-1',
	multipart => 'related'} ) ) {
		$sender->Part( {
			description => 'html body',
			ctype => 'text/html',
#			charset => 'iso-8859-1',
			charset => 'utf-8',
			encoding => 'quoted-printable',
			disposition => 'NONE',
			msg => $mensaje } );

		$sender->Close() or die "Ha fallado el cierre del mensaje! $Mail::Sender::Error\n";
} else {
	die "Error al enviar el correo: $Mail::Sender::Error\n";
}
p1:

# Usamos el atajo MailFile() para adjuntar ficheros
# If you want to attach some files:

( ref ($sender->MailFile(
	{ to =>$ldestinatarios, subject => $asunto,
		msg => $mensaje,
		file => "$fsalida1, $fsalida2"
	} ))
	and print "Correo enviado OK.\n"
) or die "$Mail::Sender::Error\n";

$dbh->disconnect( );

# borrar los excel temporales
unlink ($fsalida1, $fsalida2);

exit;

# listado equipos 
sub listaequipos {
	my @datos = ( "Nombre", 15, "Fabricante", 15, "Modelo", 14, "ID hardware", 10, "Tipo", 14, "CPU", 35, "Num CPU", 5, "MHz", 5, "Memoria", 5,
			"Disco Tamaño", 9, "Disco Libre", 9, "Dominio", 15,  "Usuario", 10, "Centro", 10, "SO", 25, "SP", 12, "Empresa Win", 15, "Propietario Win", 15,
			"Clave Windows", 30, "Tarjetas Red", 65, "Velocidad", 8, "MAC", 14, "IP", 12, "GW", 12, "Fecha Contacto", 15,
			"Proveedor", 15, "Pedido", 15, "Factura", 15, "Fecha Compra", 10, "Estado", 15, "Notas", 30);

	my ($x, $y, @elementos, @anchos);
	for ($x=0; $x<=$#datos; $x += 2) {
		$y=$x/2;
		$elementos[$y]=$datos[$x];
		$anchos[$y]=$datos[$x+1];
	}

	my ($any, $mes, $dia, $hora, $min);
	($min,$hora,$dia, $mes, $any) = (localtime)[1,2,3,4,5];
	my $fecha = sprintf("%02d%02d%04d_%02d%02d", $dia,$mes+1,$any+1900,$hora,$min);

	$fsalida1 = "$dirficheros/$nomlista1\_$fecha.xls";

	# Iniciar Excel
	my $libroexcel = Excel::Writer::XLSX->new($fsalida1);
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
			} elsif ( $row[15] =~ /unix/i ) {
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
		$orden="SELECT proveedor,pedido,factura,fechacompra,estado,notas FROM otrosdatospc WHERE hardware_id='$row[0]'";
		$sth2 = $dbh->prepare($orden);
		$sth2->execute();
		@row2 = $sth2->fetchrow_array;
		
		# convertir formato fecha
		($anyo,$mes,$dia) = $row2[3] =~ /(\d+)-(\d+)-(\d+)/;
		my $fcompra = "$dia/$mes/$anyo";
		if ( ($fcompra eq "//") || ($fcompra eq "00/00/0000") ) { $fcompra = "" }

		$row2[5] =~ s/<br>/\n/gi; # cambiar los saltos de linea html en las Notas

		$hoja1 -> write("Z$fila", $nproveedores{$row2[0]});
		$hoja1 -> write("AA$fila", $row2[1]);
		$hoja1 -> write("AB$fila", $row2[2]);
		$hoja1 -> write("AC$fila", $fcompra);
		$hoja1 -> write("AD$fila", $tipestpc{$row2[4]});
		$hoja1 -> write("AE$fila", $row2[5]);

		$fila++;
	}

	$libroexcel->close();
}


# listado dispositivos
sub listadispositivos {
	my @datos = ( "Dispositivo", 30, "Tipo", 12, "Centro", 10, "IP", 12, "Mac", 15, "Número Serie", 12, "Fecha Contacto", 15, "Notas", 50 );

	my ($x, $y, @elementos, @anchos);
	for ($x=0; $x<=$#datos; $x += 2) {
		$y=$x/2;
		$elementos[$y]=$datos[$x];
		$anchos[$y]=$datos[$x+1];
	}

	my ($any, $mes, $dia, $hora, $min);
	($min,$hora,$dia, $mes, $any) = (localtime)[1,2,3,4,5];
	my $fecha = sprintf("%02d%02d%04d_%02d%02d", $dia,$mes+1,$any+1900,$hora,$min);

	$fsalida2 = "$dirficheros/$nomlista2\_$fecha.xls";

	# Iniciar Excel
	my $libroexcel = Spreadsheet::WriteExcel->new($fsalida2);
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

	my $fila=2;
	my (@row, @row2);
	my $orden="SELECT id,description,type,macaddr FROM network_devices";
	my $sth = $dbh->prepare($orden);
	$sth->execute();
	while (@row = $sth->fetchrow_array) {
		$hoja1 -> write("A$fila", $row[1]);
		$hoja1 -> write("B$fila", $row[2]);
		$hoja1 -> write("E$fila", $row[3]);

		# ip, fecha
		my $centro = "ND";
		$orden="SELECT ip,date FROM netmap where mac='$row[3]'";
		my $sth2 = $dbh->prepare($orden);
		$sth2->execute();
		my ($ip, $fecha) = $sth2->fetchrow_array;
		if ( defined($ip) ) {
			foreach my $red ( %hredes ) {
				if ( $ip =~ /^$red/ ) {
					$centro = $hredes{ $red };
					last;
				}
			}
			$hoja1 -> write("C$fila", $centro);
			$hoja1 -> write("D$fila", $ip);
			my($anyo,$mes,$dia,$hora) = $fecha =~ /(\d+)-(\d+)-(\d+)\s+(\d+:\d+:\d+)/;
			$hoja1 -> write("G$fila", "$dia/$mes/$anyo $hora");
		} else {
			$hoja1 -> write("D$fila", " ");
			$hoja1 -> write("G$fila", " ");
		}

		# numero serie y notas
		my $numserie = my $notas = " ";
		$orden="SELECT numserie,notas FROM otrosdatosdisp where id='$row[0]'";
		$sth2 = $dbh->prepare($orden);
		if ( $sth2->execute() > 0 ) {
			($numserie, $notas) = $sth2->fetchrow_array;
			$notas =~ s/<br>/\n/g;
			$hoja1 -> write("F$fila", $numserie);
			$hoja1 -> write("H$fila", $notas);
		}

		$fila++;
	}

	$libroexcel -> close();
}

