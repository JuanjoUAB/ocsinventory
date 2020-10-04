#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	otrospc_u.pl
# DESCRIPTION:	llena el cuadro auxiliar de equipos con la informacion adicional (introducida manualmente) del PC
# AUTHOR:		José Serena
# DATE:			14/07/2014
# VERSION:		3.0

use Encode;
use strict;
#use warnings;
use DBI;
use Time::Local;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %tipestpc=();
my %nproveedores=();

my $id = $ENV{'QUERY_STRING'};

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

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# enviar la cabecera html
print "Content-type: text/html\n\n";

# leer tipos estado pc
my $row;
my $orden="SELECT id,nombre FROM tipos WHERE tipo='ESTADO'";
my $sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	$tipestpc{$row->{'id'}} = $row->{'nombre'};
}

# leer proveedores
$orden="SELECT id,nombre FROM proveedores";
$sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
        $row->{'nombre'}=decode("UTF-8",$row->{'nombre'});
       	$nproveedores{$row->{'id'}} = $row->{'nombre'};
}

$orden="SELECT proveedor,pedido,factura,fechacompra,fingarantia,estado,notas FROM otrosdatospc WHERE hardware_id='$id'";
$sth = $dbh->prepare($orden);
$sth->execute();
while ($row = $sth->fetchrow_hashref) {
	# convertir formato fecha
	# fecha compra
	my ($anyo,$mes,$dia) = $row->{'fechacompra'} =~ /(\d+)-(\d+)-(\d+)/;
	my $fcompra = "$dia/$mes/$anyo";
	if ( ($fcompra eq "//") || ($fcompra eq "00/00/0000") ) { $fcompra = "" }
	# garantia
	my $fgarantia= "";
	my $colorgar = "";
	if (exists $row->{'fingarantia'} ) {
		($anyo,$mes,$dia) = $row->{'fingarantia'} =~ /(\d+)-(\d+)-(\d+)/;
		$fgarantia = "$dia/$mes/$anyo";
		if ( $fgarantia eq "00/00/0000" ) {
			$fgarantia = ""
		} else {
			$mes = $mes-1;
			eval { timelocal(0, 0, 0, $dia, $mes, $anyo) }; # hay fechas erroneas que abortan el programa
			my $efingarantia = $@ ? 0 : timelocal(0, 0, 0, $dia, $mes, $anyo);
			# diferencia de fechas
			if ( (time-$efingarantia)/86400 > 0 ) {
				$colorgar = "red";
			} elsif ( ($efingarantia-time)/86400 < 30 ) {
				$colorgar = "yellow";
			}
		}
	}

        $row->{pedido}=decode("UTF-8",$row->{pedido});
        $row->{factura}=decode("UTF-8",$row->{factura});
        $row->{notas}=decode("UTF-8",$row->{notas});

	print "document.getElementById('tr1otrospc').cells[0].innerHTML='$nproveedores{$row->{proveedor}}';\n";
	print "document.getElementById('tr1otrospc').cells[1].innerHTML='$row->{pedido}';\n";
	print "document.getElementById('tr1otrospc').cells[2].innerHTML='$row->{factura}';\n";
	print "document.getElementById('tr1otrospc').cells[3].innerHTML='$fcompra';\n";
	print "document.getElementById('tr1otrospc').cells[4].innerHTML='$fgarantia';\n";
	print "document.getElementById('tr1otrospc').cells[4].style='background-color: $colorgar;';\n";
	print "document.getElementById('tr1otrospc').cells[5].innerHTML='$tipestpc{$row->{estado}}';\n";
	print "document.getElementById('tr1otrospc').cells[6].innerHTML='$row->{notas}';\n";
}

$dbh->disconnect( );
exit;
