#!/usr/bin/env bash
# Vercel Linux build: install Flutter SDK (cached in $HOME) and compile web.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE="${API_BASE:-https://hexpenses-api.onrender.com/api}"
export PATH="${HOME}/flutter_stable/bin:${PATH}"

if [[ ! -x "${HOME}/flutter_stable/bin/flutter" ]]; then
  echo "Cloning Flutter stable (one-time per build machine)..."
  rm -rf "${HOME}/flutter_stable"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${HOME}/flutter_stable"
fi

flutter config --no-analytics
flutter precache --web
flutter pub get
flutter build web --release --dart-define="API_BASE=${API_BASE}"
