#!/usr/bin/env bash
# Génère le PDF de la documentation SFD/STD à partir de doc/sfd-std.md.
#
# Usage : bash doc/tools/build.sh
#
# Contrairement au dépôt web, les captures d'écran ne sont pas générées ici :
# une application mobile ne se pilote pas en ligne de commande. Elles sont
# réalisées à la main depuis un émulateur ou un téléphone, puis déposées dans
# doc/images/ sous les noms attendus (les fichiers vides du dossier servent de
# gabarit : 01-connexion.png, 02-erreur-identifiants.png, etc.).
#
# Capture rapide depuis un appareil ou un émulateur Android :
#   adb exec-out screencap -p > doc/images/01-connexion.png
#
# Prérequis (poste de la maîtrise d'œuvre uniquement) :
#   - php, google-chrome-stable (ou $CHROME), pdfinfo et pdftotext (poppler-utils) ;
#   - le dépôt web cloné à côté de celui-ci, avec 'composer install' déjà lancé :
#     md2pdf.php y prend league/commonmark (chemin surchargeable par $AUTOLOAD).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "▶ PDF"
php doc/tools/md2pdf.php doc/sfd-std.md doc/sfd-std.pdf
echo "✔ doc/sfd-std.pdf"
