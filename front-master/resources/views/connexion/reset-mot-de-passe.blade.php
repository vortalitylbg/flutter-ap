@extends('layouts.app')

@section('titre', 'Nouveau mot de passe – ResaChev')

@section('contenu')
    <div class="row justify-content-center">
        <div class="col-md-5">

            <h1 class="mb-2">Nouveau mot de passe</h1>
            <p class="text-muted mb-4">Choisissez un nouveau mot de passe pour votre compte.</p>

            @if ($errors->any())
                <div class="alert alert-danger">
                    {{ $errors->first() }}
                </div>
            @endif

            <form action="{{ route('connexion.reset.enregistrer', $token) }}" method="POST">
                @csrf

                <div class="mb-3">
                    <label for="motpasse" class="form-label">Nouveau mot de passe</label>
                    <input type="password"
                           id="motpasse"
                           name="motpasse"
                           class="form-control @error('motpasse') is-invalid @enderror"
                           required
                           autofocus>
                    @error('motpasse')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="mb-4">
                    <label for="motpasse_confirmation" class="form-label">Confirmer le mot de passe</label>
                    <input type="password"
                           id="motpasse_confirmation"
                           name="motpasse_confirmation"
                           class="form-control @error('motpasse_confirmation') is-invalid @enderror"
                           required>
                    @error('motpasse_confirmation')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="d-grid">
                    <button type="submit" class="btn btn-dark">Enregistrer</button>
                </div>

            </form>

        </div>
    </div>
@endsection
