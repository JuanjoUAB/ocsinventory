#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	aut.pl
# DESCRIPTION:	comprueba si el usuario se ha autenticado
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0


use strict;
#use warnings;
use Crypt::Crypto;

my $cripto = Crypt::Crypto->new();

# comprobar autorizacion
my $ipremota = $ENV{'REMOTE_ADDR'};
my $galletas = $ENV{'HTTP_COOKIE'};

# buscar galleta SESIONINV con el nombre del usuario, ip y la expiracion encriptados
my @galletas = split /;/,$galletas;
my $usuario = '';
my $iporigen = '';
foreach my $galleta ( @galletas ) {
	my ($nombre, $valor) = split /=/,$galleta;
	if ( $nombre eq 'SESIONINV' ) {
		($usuario, $iporigen) = split /;/,$cripto->decryptA($valor)
	}
}

# comprobar si es la misma IP que autorizamos
if ( $ipremota ne $iporigen ) {
	# saltar a la pagina de autorizacion
	print "Content-type: text/html\n\n";
	print "window.location='index.html';\n";
	exit;
}

exit;
