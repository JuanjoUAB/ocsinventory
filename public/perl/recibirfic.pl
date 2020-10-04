#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	recibirfic.pl
# DESCRIPTION:	recibe y graba un fichero enviado por el cliente
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use strict;
use CGI;
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;

$CGI::POST_MAX = 1024 * 10000; # 10 MB de tamaño maximo

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

my $query = new CGI;

my $nombrefic = $query->param("fichero");
exit if ( !$nombrefic );

my ( $nombre, $path, $extension ) = fileparse ( $nombrefic, '..*' );
$nombrefic = $nombre . $extension;
# convertir caracteres especiales
$nombrefic =~ tr/ /_/;
$nombrefic =~ tr/ÀÁÂÃÄÅàáâãäå/a/;
$nombrefic =~ tr/ÈÉÊËèéêë/e/;
$nombrefic =~ tr/ÌÍÎÏìíîï/i/;
$nombrefic =~ tr/ÒÓÔÕÖØòóôõöø/o/;
$nombrefic =~ tr/ÙÚÛÜùúûü/u/;
$nombrefic =~ tr/ÇçÑñÝýÿ/ccnnyyy/;
$nombrefic =~ s/ß/ss/g;

my $fh_descarga = $query->upload("fichero");

open ( UPLOADFILE, ">", "$dirdocs/$nombrefic" ) or die "$!";
binmode UPLOADFILE;
while ( <$fh_descarga> ) {
	print UPLOADFILE;
}
close UPLOADFILE;

# borrar indicador estamos grabando el fichero real
unlink "$dirdocs/$nombrefic.lck";

exit;