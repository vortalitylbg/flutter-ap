@extends('layouts.app')

@section('titre', 'Mon QR Code – ResaChev')

@push('styles')
    <link href="/css/print.css" rel="stylesheet">
@endpush

@section('contenu')
    <div class="d-flex align-items-center justify-content-between mb-4 no-print">
        <h1 class="h3 mb-0">Mon QR Code</h1>
        @if ($prochaineReservation)
            <button onclick="window.print()" class="btn btn-outline-secondary btn-sm">Imprimer le billet</button>
        @endif
    </div>

    @if ($prochaineReservation)
        <div class="billet-wrapper">
            <div class="billet">
                <div class="billet-header">
                    <div class="marque">ResaChev</div>
                    <div class="sous-titre">Billet de réservation</div>
                </div>
                <div class="billet-body">
                    <div class="billet-prestation">{{ $prochaineReservation->prestation->libelleprestation }}</div>
                    <div class="billet-client">{{ $utilisateur->prenom }} {{ $utilisateur->nom }}</div>
                    <hr class="billet-separateur">
                    <div class="billet-date">
                        {{ $prochaineReservation->datedebut->translatedFormat('l d F Y') }}
                    </div>
                    <div class="billet-heure">{{ $prochaineReservation->heuredebut->format('H:i') }}</div>
                    <hr class="billet-separateur">
                    <div class="billet-qr">
                        <div id="qrcode"></div>
                    </div>
                    <div class="billet-footer">
                        Réservation n°{{ $prochaineReservation->idreservation }} &mdash; À présenter au staff
                    </div>
                </div>
            </div>
        </div>
    @else
        <div class="alert alert-secondary">Aucune réservation à venir — aucun QR code à afficher.</div>
    @endif
@endsection

@push('scripts')
    <script src="/js/qrcode.min.js"></script>
    @if ($prochaineReservation)
        <script>
            // Le code suivant génère un QRCode dans l'élément qui a comme ID qrcode.
            new QRCode(document.getElementById('qrcode'), {
                text: '{{ $prochaineReservation->idreservation }}',
                width: 200,
                height: 200,
                colorDark: '#000000',
                colorLight: '#ffffff',
                correctLevel: QRCode.CorrectLevel.H,
            });
        </script>
    @endif
@endpush
