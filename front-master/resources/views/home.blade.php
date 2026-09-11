@extends('layouts.app')

@section('titre', 'Accueil – ResaChev')

@section('contenu')

    {{-- Hero --}}
    <div class="px-4 py-5 mb-5 text-center border-bottom">
        <h1 class="display-5 fw-bold">Bienvenue sur {{ $nomPlatform }}</h1>
        <p class="col-lg-6 mx-auto lead text-muted">
            Réservez vos créneaux en ligne en quelques clics. Consultez vos rendez-vous,
            gérez votre profil et présentez votre QR code à l'accueil.
        </p>
        <div class="d-grid gap-2 d-sm-flex justify-content-sm-center mt-4">
            @auth
                <a href="{{ route('espace.dashboard') }}" class="btn btn-dark btn-lg px-4">Mon compte</a>
            @else
                <a href="{{ route('connexion') }}" class="btn btn-dark btn-lg px-4">Se connecter</a>
            @endauth
        </div>
    </div>

    {{-- Fonctionnalités --}}
    <div class="row g-4 mb-5">
        <div class="col-md-4">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body p-4">
                    <h5 class="card-title fw-semibold">Réservation en ligne</h5>
                    <p class="card-text text-muted">
                        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
                        incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.
                    </p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body p-4">
                    <h5 class="card-title fw-semibold">Suivi de vos créneaux</h5>
                    <p class="card-text text-muted">
                        Quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
                        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.
                    </p>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body p-4">
                    <h5 class="card-title fw-semibold">Validation par QR code</h5>
                    <p class="card-text text-muted">
                        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt
                        mollit anim id est laborum. Curabitur pretium tincidunt lacus.
                    </p>
                </div>
            </div>
        </div>
    </div>

    {{-- Section secondaire --}}
    <div class="row align-items-center g-5 py-4 border-top">
        <div class="col-md-6">
            <h2 class="fw-bold">Gérez vos rendez-vous simplement</h2>
            <p class="text-muted">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla facilisi.
                Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.
                Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante.
            </p>
            <p class="text-muted">
                Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est.
                Mauris placerat eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra.
            </p>
        </div>
        <div class="col-md-6">
            <div class="bg-light rounded-3 p-5 text-center text-muted fst-italic">
                Illustration à venir
            </div>
        </div>
    </div>

@endsection
