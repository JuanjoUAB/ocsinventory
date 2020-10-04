// cabecera de las paginas, depende del cliente
document.write('\
	<style>\
	#linea { width:100%; height:50px; background-color:#000000; margin-bottom:5px;}\
	#titulo { float:left; width:45%; color:white; font-weight:bold; font-size:30px; line-height:50px; margin-left:20px; }\
	#logo { width:30%; }\
	#logo img { height:50px; }\
	#exit { width:25%; }\
	#exit a { float:right; margin-right:0px; width:50px; height:50px; -moz-box-sizing:border-box; box-sizing:border-box; background:url("../img/exit_white.png") center no-repeat;}\
	#exit a:hover { height:50px; -moz-box-sizing:border-box; box-sizing:border-box; background:url("../img/exit_red.png") center no-repeat; }\
	</style>\
	<div id="linea">\
		<span id="titulo">'+titulo+'</span>\
		<span id="logo"><img src="../img/logoUAB-BN.png"></span>\
		<span id="exit"><a href="index.php?logout=1" title="logout"></a></span>\
	</div>\
');
