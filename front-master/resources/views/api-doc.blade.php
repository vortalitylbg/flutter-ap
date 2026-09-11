@extends('layouts.app')

@section('titre', 'Documentation API – ResaChev')

@section('contenu')
    <div class="card">
        <div class="card-header">
            <h1 class="card-title h4 mb-0">Documentation de l'API mobile</h1>
        </div>
        <div class="card-body">
            <p class="text-muted">Cette page présente la documentation de l'API utilisée par l'application mobile Flutter (staff terrain).</p>
            <div id="swagger-ui"></div>
        </div>
    </div>
@endsection

@push('styles')
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
    <style>
        .swagger-ui .topbar { display: none; }
    </style>
@endpush

@push('scripts')
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
    <script>
        window.onload = function () {
            SwaggerUIBundle({
                url: "{{ asset('api/doc-api.yaml') }}",
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIStandalonePreset
                ],
                plugins: [
                    SwaggerUIBundle.plugins.DownloadUrl
                ],
                layout: "StandaloneLayout"
            });
        };
    </script>
@endpush
