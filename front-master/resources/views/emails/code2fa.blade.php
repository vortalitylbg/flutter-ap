<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
</head>
<body>
    <p>Bonjour {{ $prenom }},</p>
    <p>Voici votre code de connexion :</p>
    <p style="font-size: 2em; font-weight: bold; letter-spacing: 0.3em;">{{ $code }}</p>
    <p>Ce code est valable 10 minutes.</p>
    <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
</body>
</html>
