#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Genera el "scaffolding" nativo que Flutter crea automáticamente (iconos,
# storyboards, project.pbxproj, gradle wrapper...) SIN sobrescribir el código
# de este repositorio.
#
# Uso:
#   ./scripts/bootstrap.sh
#
# Requisitos: Flutter 3.22+ en el PATH.
# ---------------------------------------------------------------------------
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Flutter: $(flutter --version | head -1)"

echo "==> Generando proyecto temporal en $TMP_DIR/app"
flutter create \
  --org com.pulso \
  --project-name pulso_basket \
  --platforms=android,ios \
  --empty \
  "$TMP_DIR/app" >/dev/null

echo "==> Copiando solo los archivos que faltan (--ignore-existing)"
# --ignore-existing respeta TODO el código ya versionado: manifest, gradle,
# MainActivity.kt, AppDelegate.swift, Info.plist, Podfile, etc.
if command -v rsync >/dev/null 2>&1; then
  rsync -a --ignore-existing "$TMP_DIR/app/" "$PROJECT_DIR/"
else
  echo "rsync no está instalado; usando cp -n (puede fallar en subdirectorios)"
  cp -rn "$TMP_DIR/app/." "$PROJECT_DIR/"
fi

cd "$PROJECT_DIR"
echo "==> flutter pub get"
flutter pub get

echo ""
echo "Listo. Siguiente paso:"
echo "  flutter run                 # probar en un dispositivo real"
echo "  flutter build apk --release # APK Android"
echo "  ./scripts/ios_check.sh      # iOS: valida el proyecto antes de abrir Xcode"
echo "  open ios/Runner.xcworkspace # iOS (ver docs/IPHONE.md)"
