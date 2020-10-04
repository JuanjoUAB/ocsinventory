#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	descargarfic.pl
# DESCRIPTION:	lanza la descarga web del fichero de exportacion
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
#use warnings;

# leer el nombre del fichero pasado por una qs
my $fsalida = $ENV{'QUERY_STRING'};
my ($nomfic) = $fsalida =~ /.*\/(.*)/;

# descarga del fichero por el navegador del cliente
open(FENT, "<", $fsalida) || Error('abrir', 'fichero');
binmode(FENT);
my @contenido = <FENT>; 
close (FENT) || error ('cerrar', 'fichero'); 

print "Content-Type:application/x-download\n"; 
print "Content-Disposition:attachment;filename=$nomfic\n\n";
binmode(STDOUT);
print @contenido;
unlink $fsalida;

exit;

sub error {
	print "Content-type: text/html\n\n";
	print "El servidor no puede $_[0] el $_[1]: $! \n";
	exit;
}

