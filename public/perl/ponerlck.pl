#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	ponerlck.pl
# DESCRIPTION:	cre
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;

# leer el nombre del fichero
my $nombrefic = $ENV{'QUERY_STRING'};
$nombrefic =~ s/(%(..))/chr(hex($2))/ge;
# convertir caracteres especiales
$nombrefic =~ tr/ÀÁÂÃÄÅàáâãäå/a/;
$nombrefic =~ tr/ÈÉÊËèéêë/e/;
$nombrefic =~ tr/ÌÍÎÏìíîï/i/;
$nombrefic =~ tr/ÒÓÔÕÖØòóôõöø/o/;
$nombrefic =~ tr/ÙÚÛÜùúûü/u/;
$nombrefic =~ tr/ÇçÑñİıÿ/ccnnyyy/;
$nombrefic =~ s/ß/ss/g;

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
my $dirdocs;
if (-e $fconf) {
	open (FILECONF, "<", "$fconf");
	while (<FILECONF>) {
		chomp;
		if (/^#/) {next;}
		if (/dir documentos:(.*)/) {
			$dirdocs = $1;
			$dirdocs =~ s/^\s+//;
			$dirdocs =~ s/\s+$//;
		}
	}
	close FILECONF;
} else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}

# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

# fichero indicador estamos grabando el fichero real
open (FLCK, ">", "$dirdocs/$nombrefic.lck");
close FLCK;

exit;