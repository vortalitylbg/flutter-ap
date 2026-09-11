@extends('layouts.app')

@section('titre', 'Vérification – ResaChev')

@section('contenu')
    <div class="row justify-content-center">
        <div class="col-md-5">

            <h1 class="mb-2">Vérification</h1>
            <p class="text-muted mb-4">Un code à 6 chiffres a été envoyé à votre adresse email. Il est valable 10 minutes.</p>

            @if ($errors->any())
                <div class="alert alert-danger">
                    {{ $errors->first() }}
                </div>
            @endif

            <form action="{{ route('connexion.verify2fa') }}" method="POST">
                @csrf

                <div class="mb-4">
                    <label for="code" class="form-label">Code de vérification</label>
                    <input type="text"
                           id="code"
                           name="code"
                           class="form-control form-control-lg text-center tracking-widest @error('code') is-invalid @enderror"
                           maxlength="6"
                           inputmode="numeric"
                           autocomplete="one-time-code"
                           autofocus
                           placeholder="000000">
                    @error('code')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="d-grid">
                    <button type="submit" class="btn btn-dark">Valider</button>
                </div>

            </form>

        </div>
    </div>
@endsection
