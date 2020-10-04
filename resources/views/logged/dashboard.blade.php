@extends('layouts.logged')

@section('content')
    <div class="content">
        <h1>Inventario de dispositivos y redes OCS</h1>
        <button id="btn-open-vid" class="btn btn-primary">Tutorial de nuevos dispositivos</button>
        <div id="video-tutorial" class="col-5 d-none">
            <video style='border: 5px solid white;' id='tutorial' controls muted width="640">
                <source src='https://videosdigitals.uab.cat/almacen/downloads/556/9268.mp4' type='video/mp4'>
                El teu navegador no pot reproduir el tutorial.
            </video>
        </div>
    </div>
@endsection
@section('bottom_javascript')
    <script>
        $('#btn-open-vid').click(() => {
           $('#video-tutorial video')[0].play();
           $('#video-tutorial').removeClass('d-none');
        });
    </script>
@endsection
