#!/usr/bin/env bash
# Génère la documentation SFD/STD : base SQLite temporaire, captures d'écran, PDF.
# Usage : bash doc/tools/build.sh            (tout)
#         bash doc/tools/build.sh pdf        (PDF uniquement, sans captures)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
PORT=8765
WORK="$(mktemp -d)"
trap 'kill ${SERVER_PID:-} 2>/dev/null || true; rm -rf "$WORK"' EXIT

if [[ "${1:-all}" == "all" ]]; then
  echo "▶ Base SQLite temporaire + seed"
  touch "$WORK/db.sqlite"
  # Les variables d'environnement priment sur .env : la BDD MySQL n'est jamais touchée.
  export APP_ENV=local APP_DEBUG=false APP_URL="http://127.0.0.1:$PORT"
  export DB_CONNECTION=sqlite DB_DATABASE="$WORK/db.sqlite"
  export AUTH_2FA_ENABLED=true MAIL_MAILER=log LOG_CHANNEL=single LOG_LEVEL=debug
  export CACHE_STORE=file SESSION_DRIVER=file
  : > storage/logs/laravel.log
  php artisan migrate:fresh --force --no-interaction -q
  # Les migrations ne créent que le schéma : les données de référence (role,
  # parametrage, prestation) sont dans ReferenceSeeder. Sans cet
  # appel, seed-demo.php échoue (clé étrangère idrole) et le site ne démarre pas.
  # ReferenceSeeder et non --seed : seed-demo.php fournit ses propres comptes.
  php artisan db:seed --class=ReferenceSeeder --force --no-interaction -q
  php artisan tinker --execute="require 'doc/tools/seed-demo.php';"

  echo "▶ Serveur de développement sur le port $PORT"
  php artisan serve --host=127.0.0.1 --port=$PORT >"$WORK/serve.log" 2>&1 &
  SERVER_PID=$!
  for _ in $(seq 1 30); do curl -sf "http://127.0.0.1:$PORT/" >/dev/null && break; sleep 0.3; done

  echo "▶ Captures d'écran"
  LOG_FILE=storage/logs/laravel.log node doc/tools/screenshots.mjs "http://127.0.0.1:$PORT" doc/images
  kill $SERVER_PID; unset SERVER_PID
fi

echo "▶ PDF"
php doc/tools/md2pdf.php doc/sfd-std.md doc/sfd-std.pdf
echo "✔ doc/sfd-std.pdf"
