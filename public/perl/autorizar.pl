#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	autorizar.pl
# DESCRIPTION:	comprueba las credenciales del usuario por BD OCS o AD
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

# usar diferente encriptacion para la galleta. La encriptacion normal del qs es visible, la de la galleta solo se usara desde .pl
# necesitamos la url origen o siempre enviaremos al menu

use strict;
#use warnings;

use DBI;
use Net::LDAP;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

my %datos=();

my $iporigen = $ENV{'REMOTE_ADDR'};

# leer los datos pasados por una qs
my $qs = $ENV{'QUERY_STRING'};
my $datos = $cripto->decryptB($qs);
# separar los datos
my @valores = split /&/,$datos;
foreach my $dato ( @valores ) {
	my($campo,$valor) =  split /=/,$dato;
	$datos{$campo} = $valor;
}

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
my ($servidorocs, $seguridad, $usuario, $tmp, $password, $basedatos, $servidorad, @servidoresldap, $usuldap, $passwordldap, $grupoldap, $basednusu);
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
		if (/servidor AD:(.*)/) {
			$servidorad = $1;
			$servidorad =~ s/^\s+//;
			$servidorad =~ s/\s+$//;
			push @servidoresldap,$servidorad;
		}
		elsif (/usuario LDAP:(.*)/) {
			$usuldap = $1;
			$usuldap =~ s/^\s+//;
			$usuldap =~ s/\s+$//;
		}
		elsif (/password LDAP:(.*)/) {
			$tmp = $1;
			$tmp =~ s/^\s+//;
			$tmp =~ s/\s+$//;
			$passwordldap = $cripto->decryptA($tmp);
		}
		elsif (/grupo LDAP autorizado:(.*)/) {
			$grupoldap = $1;
			$grupoldap =~ s/^\s+//;
			$grupoldap =~ s/\s+$//;
		}
		elsif (/basedn usuarios AD:(.*)/) {
			$basednusu = $1;
			$basednusu =~ s/^\s+//;
			$basednusu =~ s/\s+$//;
		}
	}
	close FILECONF;
}
else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}

# primero intentamos autenticar con la BD de OCS
# si no existe el usuario y esta definido un servidor LDAP intentaremos por LDAP 

# Conectar con la base de datos de OCS
my $dbh = DBI->connect("dbi:mysql:host=$servidorocs;database=$basedatos", $usuario, $password,
			   { RaiseError => 1, AutoCommit => 1, LongReadLen => 2000, LongTruncOk => 'true' }) || die "No se ha podido contactar con la base de datos: $DBI::errstr";

# password usuario
#my $orden="SELECT passwd FROM operators WHERE id='$datos{'nombre'}' AND ACCESSLVL='1'";
my $orden="SELECT passwd FROM operators WHERE id='$datos{'nombre'}'";
my $sth = $dbh->prepare($orden);
$sth->execute();
my @row = $sth->fetchrow_array;

if ( !$row[0] ) { # no se ha encontrado el usuario en OCS
	if ( $servidorad ) { # probar con LDAP
		#conectar con un servidor LDAP
		my $ldap;
		my $cuenta;
		until( $ldap = Net::LDAP->new(\@servidoresldap, version => 3, timeout=>5) ) {
			if ( ++$cuenta > 5 ) {
				print "Content-type: text/html\n\n";
				print "document.getElementById(\"error_nombre\").innerHTML=\"No se ha encontrado un servidor LDAP\";\n";
				exit;
			}
			sleep 1;
		}

		my $res = $ldap->bind($usuldap, password => $passwordldap);
		if ( $res->code ) {
			print "Content-type: text/html\n\n";
			print "document.getElementById(\"error_nombre\").innerHTML=\"Error al entrar en el servidor LDAP\";\n";
			exit;
		}

		# Consulta ldap al servidor para encontrar al usuario
		$res = $ldap->search( base => $basednusu,
							scope  => 'sub', #  'base' , 'one', 'sub'
							deref  => 'never', #  'never', 'search', 'find', 'always'
							attrs  => [ "cn", "memberOf" ],
							filter => "& (objectclass=user) (sAMAccountName=$datos{'nombre'})"
							);
		if ( $res->code ) {
			print "Content-type: text/html\n\n";
			print "document.getElementById(\"error_nombre\").innerHTML=\"Error consulta LDAP\";\n";
			exit;
		}
		if ( !$res->count( )) {
			print "Content-type: text/html\n\n";
			print "document.getElementById(\"error_nombre\").innerHTML=\"Usuario desconocido\";\n";
			exit;
		}

		if ( $res->count( ) > 1) {
			print "Content-type: text/html\n\n";
			print "document.getElementById(\"error_nombre\").innerHTML=\"Multiples usuarios\";\n";
			exit;
		}

		my $entrada = $res->entry(0);
		my $dnusu = $entrada->dn;
		my @gruposusu = $entrada->get_value('memberOf');

		# Comprobar contraseña
		$res = $ldap->bind($dnusu, password => $datos{'password'});
		if ( $res->code ) {
			print "Content-type: text/html\n\n";
			print "document.getElementById(\"error_password\").innerHTML=\"La contraseña no es correcta\";\n";
			exit;
		}

		# Comprobar si es miembro del grupo autorizado
		my $esmiembro = 1;
		foreach my $grupo ( @gruposusu ) {
			if ( lc($grupo) eq lc($grupoldap) ) { $esmiembro = 0 }
		}
		if ( $esmiembro ) {
			print "Content-type: text/html\n\n";
			print "document.getElementById(\"error_nombre\").innerHTML=\"Usuario no autorizado\";\n";
			exit;
		}
	} else { # no se ha encontrado el usuario en OCS y no hay servidor LDAP
		print "Content-type: text/html\n\n";
		print "document.getElementById(\"error_nombre\").innerHTML=\"Usuario desconocido\";\n";
		exit;
	}
} elsif ( $datos{'passwordMD5'} ne $row[0] ) {
	print "Content-type: text/html\n\n";
	print "document.getElementById(\"error_password\").innerHTML=\"La contraseña no es correcta\";\n";
	exit;
}

# crear valor galleta con nombre usuario e ip encriptado
my $valgalleta = $cripto->encryptA("$datos{'nombre'};$iporigen");

# enviar la cabecera html
print "Content-type: text/html\n";
print "Set-Cookie: SESIONINV=$valgalleta; path=/\n";
print "\n";

# ir a la pagina inicial
#print $q->redirect( $datos{urlorigen'} );
#print "Location: $datos{urlorigen'}\n\n";
print "window.location='index.html';\n";

exit;
