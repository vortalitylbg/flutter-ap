@extends('layouts.app')

@section('titre', 'Connexion – ResaChev')

@section('contenu')
    <div class="row justify-content-center">
        <div class="col-md-5">

            <h1 class="mb-4">Connexion</h1>

            @if (session('statut'))
                <div class="alert alert-success">
                    {{ session('statut') }}
                </div>
            @endif

            @if ($errors->any())
                <div class="alert alert-danger">
                    {{ $errors->first() }}
                </div>
            @endif

            <form action="{{ route('connexion.login') }}" method="POST">
                @csrf

                <div class="mb-3">
                    <label for="email" class="form-label">Adresse email</label>
                    <input type="email"
                           id="email"
                           name="email"
                           class="form-control @error('email') is-invalid @enderror"
                           value="{{ old('email') }}"
                           required
                           autofocus>
                    @error('email')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="mb-4">
                    <div class="d-flex justify-content-between align-items-center">
                        <label for="motpasse" class="form-label mb-0">Mot de passe</label>
                        <a href="{{ route('connexion.motdepasseoublie') }}" class="small text-muted">Mot de passe oublié ?</a>
                    </div>
                    <input type="password"
                           id="motpasse"
                           name="motpasse"
                           class="form-control @error('motpasse') is-invalid @enderror"
                           required>
                    @error('motpasse')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="d-grid">
                    <button type="submit" class="btn btn-dark">Se connecter</button>
                </div>

            </form>

        </div>
    </div>
@endsection
