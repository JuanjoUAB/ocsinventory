#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	despertar_e.pl
# DESCRIPTION:	envia el paquete magico a las estaciones seleccionadas
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use Time::Local;
use Socket;

my ($linea, $estacion, $estaciones, $ip, $mascara, $mac);
my $DEFAULT_PORT = getservbyname('discard', 'udp'); # puerto por defecto para enviar el paquete m\xE1gico = 9 (descartar)

# leer parametros pasados
if ($ENV{'REQUEST_METHOD'} eq "GET") {
	$estaciones = $ENV{'QUERY_STRING'};
} elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN, $estaciones, $ENV{'CONTENT_LENGTH'}) || die "No puedo leer los parametros\n";
} 

my @estaciones = split /;/,$estaciones;
my $tipodifusion = shift @estaciones;

# enviar la cabecera html
print "Content-type: text/html\n\n";

if ( $tipodifusion eq "general" ) {
	foreach $linea ( @estaciones ) {
		($estacion, $ip, $mascara, $mac) = split /,/, $linea;
		despertarbro( $estacion, $ip, $mac );
	}
} elsif ( $tipodifusion eq "subred" ){
	foreach $linea ( @estaciones ) {
		($estacion, $ip, $mascara, $mac) = split /,/, $linea;
		despertarsub( $estacion, $ip, $mascara, $mac );
	}
} elsif ( $tipodifusion eq "ip" ){
	foreach $linea ( @estaciones ) {
		($estacion, $ip, $mascara, $mac) = split /,/, $linea;
		despertarip( $estacion, $ip, $mac );
	}
}

exit;

#
# despertar enviando un paquete a la direccion de broadcast de la subred
#
# el paquete m\xE1gico consiste en 6 bytes 0xFF seguido de 16 veces
# la direccion hardware (mac) de la tarjeta de red. Esta secuencia
# puede ser encapsulada en cualquier clase de paquete, en nuestro
# caso un paquete UDP dirigido al puerto $DEFAULT_PORT.
#                                                                               
sub despertarsub {
	my ($estacion, $ip, $mascara, $mac) = @_;
	my ($iaddr);

	# calculamos la ip de broadcast de la subred
	my @pip = split /\./,$ip;
	my @pmas = split /\./,$mascara;
	@pip = map ((pack "C",$_), @pip);
	@pmas = map ((~pack "C",$_), @pmas);
	my $ipbr = join ".", (unpack "C",$pip[0] | $pmas[0]), (unpack "C",$pip[1] | $pmas[1]), (unpack "C",$pip[2] | $pmas[2]), (unpack "C",$pip[3] | $pmas[3]);	

	if (!defined($iaddr = inet_aton($ipbr))) {
		print "No se puede resolver la IP $ipbr<br>\n";
		return;
	}

	print "Enviado el paquete m&aacutegico a $estacion ($ip, $mac, $ipbr)<br>\n";

	# eliminar separador
	$mac =~ tr/://d;

	my $magic = ("\xff" x 6) . (pack('H12', $mac) x 16);

	# Crear socket
	socket(S, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "socket: $!\n";
	# Enable broadcast
#	setsockopt(S, SOL_SOCKET, SO_BROADCAST, 1) or die "setsockopt: $!\n";
	# enviar el paquete m\xE1gico
	defined(send(S, $magic, 0, sockaddr_in($DEFAULT_PORT, $iaddr)))
		or print "Error al enviar el paquete m\xc3\xa1gico a $estacion: $!<br>\n";
	close(S);
}

sub despertarbro {
	my ($estacion, $ip, $mac) = @_;
	print "Enviado el paquete m\xc3\xa1gico a $estacion (255.255.255.255, $mac)<br>\n";
	# eliminar separador
	$mac =~ tr/://d;

	my $magic = ("\xff" x 6) . (pack('H12', $mac) x 16);

	# Crear socket
	socket(S, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "socket: $!\n";
	# Enable broadcast
	setsockopt(S, SOL_SOCKET, SO_BROADCAST, 1) or die "setsockopt: $!\n";
	# enviar el paquete m\xE1gico
	defined(send(S, $magic, 0, sockaddr_in($DEFAULT_PORT, INADDR_BROADCAST)))
		or print "Error al enviar el paquete m\xc3\xa1gico a $estacion: $!<br>\n";
	close(S);

}
                                                                           
sub despertarip {
	my ($estacion, $ip, $mac) = @_;
	my ($iaddr);

	if (!defined($iaddr = inet_aton($ip))) {
		print "No se puede resolver la IP $ip<br>\n";
		return;
	}

	print "Enviado el paquete m&aacutegico a $estacion ($ip, $mac)<br>\n";

	# eliminar separador
	$mac =~ tr/://d;

	my $magic = ("\xff" x 6) . (pack('H12', $mac) x 16);

	# Crear socket
	socket(S, PF_INET, SOCK_DGRAM, getprotobyname('udp')) or die "socket: $!\n";
	# enviar el paquete magico
	defined(send(S, $magic, 0, sockaddr_in(0x2fff, $iaddr)))
		or print "Error al enviar el paquete m\xc3\xa1gico a $estacion: $!<br>\n";
	close(S);

}
