
use Time::Local;
use MIME::Base64;
use Mail::Sender;
use Archive::Zip;

# datos correo
my $servidorcorreo = "127.0.0.1";
my $remitente = 'informes_antispam@deretil.com';
my $ldestinatarios = 'jserena@escuda.cat';
my $ldestocultos = 'pepe@lab.es';
my $asunto = 'Informe semanal antispam';
my $mensaje = 'Informe semanal antispam';
my $usucorreo = 'pepe';
my $passwordcorreo = 'pepito';



# inicializar correo
my $cabecera;
if ( $usucorreo ) {
	if ( $ldestocultos ) {
		$cabecera = new Mail::Sender { smtp => "$servidorcorreo", from => "$remitente", to => "$ldestinatarios", bcc => "$ldestocultos", auth => 'PLAIN', authid => "$usucorreo", authpwd => "$passwordcorreo", TLS_allowed => 0 };
	} else {
		$cabecera = new Mail::Sender { smtp => "$servidorcorreo", from => "$remitente", to => "$ldestinatarios", auth => 'PLAIN', authid => "$usucorreo", authpwd => "$passwordcorreo", TLS_allowed => 0 };
	}
} else {
	if ( $ldestocultos ) {
		$cabecera = new Mail::Sender { smtp => "$servidorcorreo", from => "$remitente", to => "$ldestinatarios", bcc => "$ldestocultos", TLS_allowed => 0 };
	} else {
		$cabecera = new Mail::Sender { smtp => "$servidorcorreo", from => "$remitente", to => "$ldestinatarios", TLS_allowed => 0 };
	}
}
die "Error al crear el objeto correo : $Mail::Sender::Error\n" unless ref $cabecera;
print "-1-\n";


$rparcorreos = { smtp => $servidorcorreo, from => $remitente, to => $ldestinatarios, TLS_allowed => 0 };
$rparcorreos->{bcc} = "$ldestocultos" if $ldestocultos;
if ( $usucorreo ) {
	$rparcorreos->{auth} = 'PLAIN';
	$rparcorreos->{authid} = $usucorreo;
	$rparcorreos->{authpwd} = $passwordcorreo;
}
foreach $clave (keys %$rparcorreos) {
	print "$clave => $rparcorreos->{$clave}\n";
}
$cabecera2 = new Mail::Sender $rparcorreos;
print "-2-\n";
die "Error al crear el objeto correo : $Mail::Sender::Error\n" unless ref $cabecera2;

print "$rparcorreos->{authid}\n";