#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	creartablasadicionales.pl
# DESCRIPTION:	crea las tablas adicionales para las nuevas funciones
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %hmac;

# Detectar SO para ruta fichero configuracion
my ($fconf, $dirconf) ;
my $temp="/tmp";
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
	$dirconf="c:\\xampp\\cgi-bin\\inventario\\";
	$temp=$ENV{TEMP};
}


# Leer configuracion
my ($servidorocs, $empresa, $usuario, $tmp, $password, $basedatos, $diasctmin, $diasctmax, $centro);
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

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# comprobar si existe la tabla de dispositivos sin conexion
my $sth = $dbh->do("SHOW TABLES LIKE 'dispositivossc'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla
	$dbh->do("CREATE TABLE dispositivossc (
				`ID` int(11) NOT NULL AUTO_INCREMENT,
				`DESCRIPCION` varchar(255) DEFAULT NULL,
				`TIPO` varchar(50) DEFAULT NULL,
				`UBICACION` varchar(255) DEFAULT NULL,
				`ESTADO` int(11) DEFAULT NULL,
				`NUMSERIE` varchar(25) DEFAULT NULL,
				`RESPONSABLE` varchar(100) DEFAULT NULL,
				`PROVEEDOR` int(11) DEFAULT NULL,
				`PEDIDO` varchar(50) DEFAULT NULL,
				`FACTURA` varchar(50) DEFAULT NULL,				
				`FECHACOMPRA` date DEFAULT NULL,
				`NOTAS` text,
				PRIMARY KEY (`ID`),
				KEY `ID` (`ID`)				  
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de otros datos del PC
$sth = $dbh->do("SHOW TABLES LIKE 'otrosdatospc'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla
	$dbh->do("CREATE TABLE `otrosdatospc` (
				`HARDWARE_ID` int(11) NOT NULL,
				`PROVEEDOR` int(11) DEFAULT NULL,
				`PEDIDO` varchar(50) DEFAULT NULL,
				`FACTURA` varchar(50) DEFAULT NULL,
				`FECHACOMPRA` date DEFAULT NULL,
				`FINGARANTIA` date DEFAULT NULL,				
				`ESTADO` int(11) DEFAULT NULL,
				`NOTAS` text,
				PRIMARY KEY (`HARDWARE_ID`),
				KEY `PROVEEDOR` (`PROVEEDOR`)	
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de proveedores
$sth = $dbh->do("SHOW TABLES LIKE 'proveedores'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla proveedores
	$dbh->do("CREATE TABLE `proveedores` (
				`id` int(11) NOT NULL AUTO_INCREMENT,
				`nombre` varchar(255) DEFAULT NULL,
				`direccion` varchar(255) DEFAULT NULL,
				`poblacion` varchar(255) DEFAULT NULL,
				`provincia` varchar(255) DEFAULT NULL,
				`codpostal` varchar(10) DEFAULT NULL,
				`pais` varchar(50) DEFAULT 'España',
				`NIF` varchar(15) DEFAULT NULL,
				`web` varchar(255) DEFAULT NULL,
				`telefono1` varchar(25) DEFAULT NULL,
				`telefono2` varchar(25) DEFAULT NULL,
				`fax` varchar(25) DEFAULT NULL,
				`correo` varchar(50) DEFAULT NULL,
				`notas` text,
				PRIMARY KEY (`id`),
				KEY `nombre` (`nombre`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de contactos
$sth = $dbh->do("SHOW TABLES LIKE 'contactos'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla contactos
	$dbh->do("CREATE TABLE `contactos` (
				`id` int(11) NOT NULL AUTO_INCREMENT,
				`tipocont` int(11) DEFAULT NULL,	
				`nombre` varchar(50) DEFAULT NULL,
				`apellidos` varchar(255) DEFAULT NULL,
				`empresa` int(11) DEFAULT NULL,
				`cargo` varchar(50) DEFAULT NULL,				
				`telefono1` varchar(25) DEFAULT NULL,
				`telefono2` varchar(25) DEFAULT NULL,
				`correo` varchar(50) DEFAULT NULL,
				`notas` text ,
				PRIMARY KEY (`id`),
				KEY `nombre` (`nombre`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de documentos
$sth = $dbh->do("SHOW TABLES LIKE 'documentos'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla documentos
	$dbh->do("CREATE TABLE `documentos` (
				`id` int(11) NOT NULL AUTO_INCREMENT,
				`tipodoc` int(11) DEFAULT NULL,	
				`proveedor` int(11) DEFAULT NULL,
				`referencia` varchar(50) DEFAULT NULL,
				`fechadoc` date DEFAULT NULL,
				`nfichero` varchar(255) DEFAULT NULL,				
				`notas` text ,
				PRIMARY KEY (`id`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de otros datos dispositivos
$sth = $dbh->do("SHOW TABLES LIKE 'otrosdatosdisp'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla documentos
	$dbh->do("CREATE TABLE `otrosdatosdisp` (
				`ID` int(11) NOT NULL,
				`numserie` varchar(25) DEFAULT NULL,
				`notas` text,
				PRIMARY KEY (`ID`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de identificacion dispositivos
$sth = $dbh->do("SHOW TABLES LIKE 'identificaciondisp'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla identificaciondisp
	$dbh->do("CREATE TABLE `identificaciondisp` (
				`MAC` varchar(17) DEFAULT NULL,
				`conocido` varchar(1) DEFAULT NULL,
				`OS_nombre` varchar(255) DEFAULT NULL,
				`OS_familia` varchar(255) DEFAULT NULL,
				`OS_fabricante` varchar(255) DEFAULT NULL,
				`OS_tipo` varchar(255) DEFAULT NULL,
				`puertosabiertos` varchar(255) DEFAULT NULL,
				`nmap` text,
				`sysDescr` varchar(255) DEFAULT NULL,
				`sysName` varchar(255) DEFAULT NULL,
				`nbdominio` varchar(25) DEFAULT NULL,
				`nbnombre` varchar(25) DEFAULT NULL,
				PRIMARY KEY (`MAC`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla de tipos
$sth = $dbh->do("SHOW TABLES LIKE 'tipos'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla tipos
	$dbh->do("CREATE TABLE `tipos` (
				`TIPO` varchar(25) DEFAULT NULL,				
				`ID` tinyint(2) NOT NULL,
				`NOMBRE` varchar(25) DEFAULT NULL,
				KEY (`TIPO`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");

	# llenar la tabla tipos estado PC
	$dbh->do("INSERT INTO tipos VALUES ( 'ESTADO', '1', 'ACTIVO' ), ( 'ESTADO', '2', 'BAJA' ), ( 'ESTADO', '3', 'AVERIADO' ), ( 'ESTADO', '4', 'ALMACEN' ), ( 'ESTADO', '5', 'DEPOSITO' ), ( 'ESTADO', '6', 'OTRO' ) ");

	# llenar la tabla tipos de contacto
	$dbh->do("INSERT INTO tipos VALUES ( 'CONTACTO', '1', 'COMERCIAL' ), ( 'CONTACTO', '2', 'TECNICO' ), ( 'CONTACTO', '3', 'ADMINISTRACION' ), ( 'CONTACTO', '4', 'DIRECCION' ), ( 'CONTACTO', '5', 'SAT' ), ( 'CONTACTO', '6', 'OTRO' ) ");

	# llenar la tabla tipos de documento
	$dbh->do("INSERT INTO tipos VALUES ( 'DOCUMENTO', '1', 'OFERTA' ), ( 'DOCUMENTO', '2', 'PRESUPUESTO' ), ( 'DOCUMENTO', '3', 'PEDIDO' ), ( 'DOCUMENTO', '4', 'CONTRATO' ), ( 'DOCUMENTO', '5', 'ALBARAN' ), ( 'DOCUMENTO', '6', 'FACTURA' ), ( 'DOCUMENTO', '7', 'INFORMACION' ), ( 'DOCUMENTO', '8', 'OTROS' ) ");
}

# comprobar si existe la tabla netmap_old dispositivos
# $sth = $dbh->do("DROP TABLE IF EXISTS `netmap_old`");
# comprobar si existe la tabla netmap_old dispositivos
$sth = $dbh->do("SHOW TABLES LIKE 'netmap_old'");
if ( uc($sth) eq "0E0" ) {
	if ( -e "$temp/netmap_old.sql" ) { unlink "$temp/netmap.sql"}
	my $res = system( "mysqldump -u $usuario -p$password $basedatos netmap > $temp/netmap.sql" );
	if ( $res == 0 ) {
		open ( FENT, "<", "$temp/netmap.sql") or die " Error al abrir el fichero $temp/netmap.sql\n";
		open ( FSAL, ">", "$temp/netmap_old.sql") or die " Error al abrir el fichero $temp/netmap_old.sql\n";
		while ( <FENT> ) {
			$_ =~ s/netmap/netmap_old/;
			print FSAL "$_";
		}
		close FENT;
		close FSAL;
		$res = system( "mysql -u $usuario -p$password $basedatos < $temp/netmap_old.sql" );
		if ( $res ) { print "Error al crear la tabla netmap_old\n"	}
	}
}

# comprobar si existe la tabla netmap_new dispositivos
$sth = $dbh->do("SHOW TABLES LIKE 'netmap_new'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla netmap_new
	$dbh->do("CREATE TABLE `netmap_new` (
				`IP` varchar(15) NOT NULL,
				`MAC` varchar(17) NOT NULL,
				`MASK` varchar(15) NOT NULL,
				`FABRICANTE` varchar(25) NOT NULL,
				`DATE` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
				`NAME` varchar(255) DEFAULT NULL,
				PRIMARY KEY (`MAC`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
}

# comprobar si existe la tabla descripcion aplicaciones
$sth = $dbh->do("SHOW TABLES LIKE 'idaplicaciones'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla idaplicaciones
	$dbh->do("CREATE TABLE `idaplicaciones` (
				`ID` SMALLINT NOT NULL,
				`NOMBRE` varchar(50) NOT NULL,
				PRIMARY KEY (`ID`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
	# llenar la tabla descripcion aplicaciones
	$dbh->do("INSERT INTO idaplicaciones VALUES ( '1', 'Listado equipos' ), ( '3', 'Listado equipos con selección' ), ( '5', 'Listado general aplicaciones' ),
		( '7', 'Listado general impresoras' ), ( '9', 'Listado impresoras por PC' ), ( '11', 'Listado monitores' ), ( '13', 'Listado dispositivos' ),
		( '15', 'Listado dispositivos desconocidos' ) ");
}

# comprobar si existe la tabla permisos usuario, tenemos 4 bytes que identifican hasta 128 IDs de aplicaciones
$sth = $dbh->do("SHOW TABLES LIKE 'perm_usuarios'");
if ( uc($sth) eq "0E0" ) {
	# crear la tabla perm_usuarios
	$dbh->do("CREATE TABLE `perm_usuarios` (
				`USUARIO` varchar(25) DEFAULT NULL,
				`PERMISOSB1` INT DEFAULT 0,
				`PERMISOSB2` INT DEFAULT 0,
				`PERMISOSB3` INT DEFAULT 0,
				`PERMISOSB4` INT DEFAULT 0,
				PRIMARY KEY (`USUARIO`)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8;
			");
	$dbh->do("INSERT INTO perm_usuarios VALUES ( 'admin', 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF ) ");
}

# comprobar si existe la tabla de mac/fabricantes 
$sth = $dbh->do("DROP TABLE IF EXISTS `macvendor`");
# crear la tabla macvendor
$dbh->do("CREATE TABLE macvendor (
			`MAC` varchar(6),
			`FABRICANTE` varchar(60),
			PRIMARY KEY (`MAC`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;
		");

#  000001     (base 16)		XEROX CORPORATION
open (FENT, "<", $dirconf."macvendor.txt") or die "Error al abrir el fichero macvendor.txt\n";
$dbh->do("START TRANSACTION");
while ( <FENT> ) {
	if ( /base 16/) {
		my($mac, $fabricante) = $_ =~ /\s+(......)\s+\(base 16\)\s+(.*)/;
		next if ( exists $hmac{$mac} );
		$hmac{$mac} = 1; # hay macs repetidas
		chomp $fabricante;
		$fabricante =~ s/'/''/g; # error si hay una ', en BD se escapa con ''
		# llenar la tabla
		$dbh->do("INSERT INTO macvendor VALUES ( '$mac', '$fabricante' )");
	}
}
$dbh->do("COMMIT"); 
   
$dbh->disconnect( );
exit;
