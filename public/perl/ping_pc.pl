#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	ping_pc.pl
# DESCRIPTION:	hace un ping al PC y muestra el resultado coloreando la celda correspondiente
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;
use IO::Socket;

# my $puerto = 5800; # puerto javaview de UVNC
my $puerto = 5900; # puerto UVNC

# leer la fila de la tabla y la ip de la estacion pasadas por una qs
my $valores = $ENV{'QUERY_STRING'};
my ($qsfila, $qsip) = split /&/,$valores;
my ($fila) = $qsfila =~ /fila=(.*)/;
my ($ip) = $qsip =~ /ip=(.*)/;

# enviar la cabecera html
print "Content-type: text/html\n\n";

# modificar el color del texto PING de acuerdo con el resultado
#  Intentar la conexion
my $servicio = IO::Socket::INET->new(
	Proto    => "tcp",
	PeerAddr => $ip,
	PeerPort => $puerto,
	Timeout  => 5,
);

#  Ver respuesta
if ($servicio) {
	close $servicio;
	print "\$('#$fila').attr('style', 'color: #00FF00 !important')\n";
} else {
	print "\$('#$fila').attr('style', 'color: #FF0000 !important')\n";
}

exit;
