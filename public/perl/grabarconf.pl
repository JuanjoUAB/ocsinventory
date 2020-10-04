#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	grabarconf.pl
# DESCRIPTION:	grabar en el fichero inventario.cfg los nuevos valores entrados
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use Encode;
use strict;
#use warnings;

# leer los valores pasados por una qs
my $valores = $ENV{'QUERY_STRING'};
my ($qsdiasmin, $qsdiasmax, $qslistaredes) = split /&/,$valores;
my ($diasctmin) = $qsdiasmin =~ /diasmin=(.*)/;
my ($diasctmax) = $qsdiasmax =~ /diasmax=(.*)/;
my ($listaredes) = $qslistaredes =~ /listaredes=(.*)/;
# formatear la lista de redes caracteres especiales estan como %xx donde xx es evalor hex
$listaredes =~ s/(%(..))/chr(hex($2))/ge;
$listaredes =~ s/,,/\nred: /g;
$listaredes = 'red: '.$listaredes;
#$listaredes = 'red: '.encode("ISO-8859-1",$listaredes);

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

# enviar la cabecera html
print "Content-type: text/html\n\n";

# grabar configuracion
if (-e $fconf) {
	open (FILECONF, "<", "$fconf");
	open (FILECONFTMP, ">", "$fconf.tmp");
	while (<FILECONF>) {
		next if (/red:/);
		if (/dias contacto min:/) {
			$_ = "dias contacto min: $diasctmin\n";
		}
		elsif (/dias contacto max:/) {
			$_ = "dias contacto max: $diasctmax\n";
		}
		print FILECONFTMP "$_";
	}
	#$listaredes=encode("ISO-8859-1",$listaredes);
        print FILECONFTMP "$listaredes\n";
	close FILECONF;
	close FILECONFTMP;
	unlink $fconf;
	rename "$fconf.tmp", "$fconf";
}
else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}
