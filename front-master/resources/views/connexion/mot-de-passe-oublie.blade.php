@extends('layouts.app')

@section('titre', 'Mot de passe oublié – ResaChev')

@section('contenu')
    <div class="row justify-content-center">
        <div class="col-md-5">

            <h1 class="mb-2">Mot de passe oublié</h1>
            <p class="text-muted mb-4">Renseignez votre adresse email, vous recevrez un lien pour réinitialiser votre mot de passe.</p>

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

            <form action="{{ route('connexion.motdepasseoublie.envoyer') }}" method="POST">
                @csrf

                <div class="mb-4">
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

                <div class="d-grid">
                    <button type="submit" class="btn btn-dark">Envoyer le lien</button>
                </div>

            </form>

            <div class="text-center mt-3">
                <a href="{{ route('connexion') }}" class="text-muted small">Retour à la connexion</a>
            </div>

        </div>
    </div>
@endsection
