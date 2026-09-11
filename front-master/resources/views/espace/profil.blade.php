@extends('layouts.app')

@section('titre', 'Mon profil – ResaChev')

@section('contenu')
    <h1 class="h3 mb-4">Mon profil</h1>

    @if (session('statut'))
        <div class="alert alert-success">{{ session('statut') }}</div>
    @endif

    <div class="row">
        <div class="col-md-6">
            <div class="card border-0 shadow-sm">
                <div class="card-body p-4">
                    <form action="{{ route('espace.profil.update') }}" method="POST">
                        @csrf

                        <div class="mb-4">
                            <label for="nom" class="form-label">Nom</label>
                            <input type="text"
                                   class="form-control @error('nom') is-invalid @enderror"
                                   id="nom"
                                   name="nom"
                                   value="{{ old('nom', $utilisateur->nom) }}"
                                   required>
                            @error('nom')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        {{-- TODO : email, mot de passe, téléphone… --}}

                        <button type="submit" class="btn btn-primary">Modifier</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
@endsection
