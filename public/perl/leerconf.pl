#!/usr/bin/perl -w

# APP:			Listados Inventario OCS
# TITLE:	 	leerconf.pl
# DESCRIPTION:	lee del fichero de configuracion los elementos configurables
# AUTHOR:		José Serena
# DATE:			07/09/2015
# VERSION:		4.0

use Encode;
use strict;
#use warnings;

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
my ( $tmp, $diasctmin, $diasctmax, $red, @redes );
if (-e $fconf) {
	open (FILECONF, "<", "$fconf");
	while (<FILECONF>) {
		chomp;
		if (/^#/) {next;}
		if (/dias contacto min:(.*)/) {
			$diasctmin = $1;
			$diasctmin =~ s/^\s+//;
			$diasctmin =~ s/\s+$//;
		}
		elsif (/dias contacto max:(.*)/) {
			$diasctmax = $1;
			$diasctmax =~ s/^\s+//;
			$diasctmax =~ s/\s+$//;
		}
		elsif (/red:(.*)/) {
			$tmp = $1;
			$tmp =~ s/^\s+//;
			$tmp =~ s/\s+$//;
			push @redes,$tmp;
		}
	}
	close FILECONF;
}
else {
	print "No se ha encontrado el fichero de configuracion $fconf\n";
	exit(1);
}


# enviar la cabecera de la tabla
print "Content-type: text/html\n\n";

# mostrar los elementos
print "document.getElementById('diasctmin').value=$diasctmin;\n";
print "document.getElementById('diasctmax').value=$diasctmax;\n";
print "document.write('<ul id=\"listaredes\" contenteditable=\"true\">');\n";
foreach $red ( @redes ) {
        $red = caracteresespeciales($red);
        $red = decode("UTF-8", $red);
       	print "document.write('<li>$red</li>');\n";
}
print "document.write('</ul>');\n";
print "document.write('<br>');\n";

exit;

sub caracteresespeciales {
	my $linea = shift;
	$linea =~ s/'/&#39;/g;
	$linea =~ s/"/&quot;/g;
	return $linea;
}
