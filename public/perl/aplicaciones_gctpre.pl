#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	aplicaciones_gpre.pl
# DESCRIPTION:	graba por la noche en una tabla todas las aplicaciones detectadas para listarla mas rapido
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

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


# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# eliminamos la tabla actual y la recreamos
$dbh->do("DROP TABLE IF EXISTS `aplicacionesg`");

# tabla aplicaciones general precalculada para ir mas rapido
$dbh->do("CREATE TABLE IF NOT EXISTS `aplicacionesg` (
			`ID` int(11) NOT NULL AUTO_INCREMENT,
			`NUMINST` int(11) NOT NULL,
			`NOMAPP` varchar(255) DEFAULT NULL,
			`IDAPP` int(11) DEFAULT NULL,
			`FABRICANTE` varchar(255) DEFAULT NULL,
			`VERSION` varchar(255) DEFAULT NULL,
			`CARPETA` text DEFAULT NULL,
			`COMENTARIOS` text DEFAULT NULL,
			PRIMARY KEY (`ID`)
			) ENGINE=INNODB;
");

# para evitar error 'this is incompatible with sql_mode=only_full_group_by' desactivamos el modo o usamos ANY_VALUE()
#my $orden="SELECT ANY_VALUE(id) id,name,ANY_VALUE(publisher) publisher,version,ANY_VALUE(folder) folder,ANY_VALUE(comments) comments,COUNT(DISTINCT hardware_id) as instalaciones FROM softwares GROUP BY name,version ORDER BY name";
my $orden="SELECT id,name,publisher,version,folder,comments,COUNT(DISTINCT hardware_id) as instalaciones FROM softwares GROUP BY name,version ORDER BY name";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ( my $row = $sth->fetchrow_hashref ) {
	my $nombre = $row->{name} ? $row->{name} : "ND";
	$nombre = caresp($nombre);
	$nombre = longmax($nombre, 35);
	my $fab = $row->{publisher} ? $row->{publisher} : "&nbsp;";
	$fab = caresp($fab);
	$fab = longmax($fab,35);
	my $version = $row->{version} ? $row->{version} : "&nbsp;";
	$version = longmax($version,25);
	my $carpeta = $row->{folder} ? $row->{folder} : "&nbsp;";
	$carpeta = caresp($carpeta);
	my $comentario = $row->{comments} ? $row->{comments} : "&nbsp;";
	$comentario = caresp($comentario);
	$comentario = longmax($comentario,50);

	my $res = $dbh->do("INSERT INTO aplicacionesg VALUES( NULL,$row->{instalaciones},'$nombre',$row->{id},'$fab','$version','$carpeta','$comentario'  ) ");
}


$dbh->disconnect( );
exit;

# procesar caracteres que pueden confundir la orden document.write('... tales como ' < y >
sub caresp {
	my $texto = shift;
	$texto =~ s/'/&#x27;/g;
	$texto =~ s/</&#x3c;/g;
	$texto =~ s/>/&#x3e;/g;
	$texto =~ s/\n/&#x0d;/g;
	$texto =~ s/\\n//g; # tenemos el texto \n que luego se interpreta como salto linea
	$texto =~ s/\r/&#x0d;/g;	
	$texto =~ s/\t/ /g;
	return $texto;
}
# insertar blancos para que tablesorter pueda ajustar bien el ancho de la columna columna
sub longmax {
	my $texto = shift;
	my $longtrozo = shift;
	
	if ( length($texto) <= $longtrozo ) { return $texto }

	my $textosal = '';
	my $pos = 0;
	while ( length(substr($texto,$pos)) > $longtrozo ) {
		my $trozo = substr($texto,$pos,$longtrozo);
		$trozo = index($trozo, "") > 0  ? $trozo : $trozo."<br>";
		$textosal .= $trozo;
		$pos += $longtrozo;
	}
	$textosal .= substr($texto,$pos);	
	return $textosal;
}
