#!/usr/bin/env bash
# Comprobación previa del proyecto iOS de Pulso Basket.
#
# Funciona en macOS, Linux y Windows (Git Bash / WSL):
#   - siempre: valida la configuración del repo (pbxproj, plists, entitlements)
#   - en macOS: además comprueba Xcode, CocoaPods, Flutter y los pods instalados
#
# Uso:  ./scripts/ios_check.sh

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

ROJO=$'\033[31m'; VERDE=$'\033[32m'; AMARILLO=$'\033[33m'; GRIS=$'\033[90m'; FIN=$'\033[0m'
fallos=0
avisos=0

ok()      { printf "  %s✔%s %s\n" "$VERDE" "$FIN" "$1"; }
fallo()   { printf "  %s✘%s %s\n" "$ROJO" "$FIN" "$1"; fallos=$((fallos+1)); }
aviso()   { printf "  %s!%s %s\n" "$AMARILLO" "$FIN" "$1"; avisos=$((avisos+1)); }
seccion() { printf "\n%s%s%s\n" "$GRIS" "$1" "$FIN"; }

PBX="ios/Runner.xcodeproj/project.pbxproj"

seccion "1. Estructura del proyecto"
[ -f "$PBX" ] && ok "ios/Runner.xcodeproj/project.pbxproj" || fallo "falta $PBX"
for f in ios/Runner/Info.plist ios/Runner/Runner.entitlements ios/Runner/AppDelegate.swift \
         ios/Runner/LiveActivityBridge.swift ios/Runner/PulsoActivityAttributes.swift \
         ios/Runner/PulsoCommandIntent.swift ios/Podfile \
         ios/PulsoWidget/Info.plist ios/PulsoWidget/PulsoWidget.entitlements \
         ios/PulsoWidget/PulsoWidgetBundle.swift ios/PulsoWidget/PulsoLiveActivityView.swift; do
  [ -f "$f" ] && ok "$f" || fallo "falta $f"
done
for f in ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png; do
  if [ -s "$f" ]; then ok "icono de app (1024 px) presente"; else fallo "icono de app vacío: $f"; fi
done

seccion "2. Target de la Live Activity"
if grep -q "PulsoWidget" "$PBX"; then
  ok "target PulsoWidget registrado en el pbxproj"
else
  fallo "el target PulsoWidget no está en el pbxproj (ejecuta scripts/parche_widget.py)"
fi
if grep -q "Embed App Extensions" "$PBX"; then
  ok "fase 'Embed App Extensions' presente (la app empotra el widget)"
else
  fallo "falta la fase 'Embed App Extensions'"
fi
n=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = com\.pulso\.basket\.PulsoWidget;" "$PBX" 2>/dev/null || echo 0)
[ "${n:-0}" -ge 3 ] && ok "bundle id del widget en las 3 configuraciones" \
                    || fallo "bundle id del widget incompleto ($n/3)"
grep -q "IPHONEOS_DEPLOYMENT_TARGET = 16\.1;" "$PBX" && ok "widget con deployment target iOS 16.1" \
  || aviso "no se encontró IPHONEOS_DEPLOYMENT_TARGET = 16.1 (Live Activities necesita 16.1+)"

seccion "3. Permisos y capacidades (Info.plist / entitlements)"
grep -q "UIBackgroundModes" ios/Runner/Info.plist && grep -q "<string>location</string>" ios/Runner/Info.plist \
  && ok "UIBackgroundModes: location (GPS con pantalla bloqueada)" \
  || fallo "falta UIBackgroundModes/location en Runner/Info.plist"

grep -q "NSSupportsLiveActivities" ios/Runner/Info.plist \
  && ok "NSSupportsLiveActivities" || fallo "falta NSSupportsLiveActivities"
grep -q "NSSupportsLiveActivitiesFrequentUpdates" ios/Runner/Info.plist \
  && ok "NSSupportsLiveActivitiesFrequentUpdates" \
  || aviso "sin NSSupportsLiveActivitiesFrequentUpdates (refresco más lento)"

grep -q "NSLocationAlwaysAndWhenInUseUsageDescription" ios/Runner/Info.plist \
  && ok "texto de permiso 'Siempre' de ubicación" || fallo "falta NSLocationAlwaysAndWhenInUseUsageDescription"

for ent in ios/Runner/Runner.entitlements ios/PulsoWidget/PulsoWidget.entitlements; do
  grep -q "group.com.pulso.basket" "$ent" \
    && ok "App Group en $(basename "$(dirname "$ent")")" \
    || fallo "App Group ausente en $ent"
done

grep -q "pulso" ios/Runner/Info.plist && ok "esquema de URL 'pulso' declarado" \
  || aviso "no se declaró el esquema pulso:// (fallback de botones en iOS 16)"

grep -q "pulso/live_activity" ios/Runner/AppDelegate.swift \
  && ok "canal nativo pulso/live_activity" || fallo "AppDelegate no registra el canal de la Live Activity"

seccion "4. Código compartido entre app y widget"
for f in PulsoActivityAttributes.swift PulsoCommandIntent.swift; do
  if grep -q "$f in Sources" "$PBX"; then
    n=$(grep -c "$f in Sources \*/ = " "$PBX" 2>/dev/null || echo 0)
    [ "${n:-0}" -ge 2 ] && ok "$f compilado en app + widget" \
                        || fallo "$f solo está en un target (debe estar en Runner y PulsoWidget)"
  else
    fallo "$f no está en ninguna fase de compilación"
  fi
done

seccion "5. Herramientas (solo macOS)"
if [ "$(uname -s)" = "Darwin" ]; then
  command -v xcodebuild >/dev/null 2>&1 && ok "$(xcodebuild -version 2>/dev/null | head -1)" \
    || fallo "Xcode no instalado o sin xcode-select"
  command -v pod >/dev/null 2>&1 && ok "$(pod --version 2>/dev/null | tail -1 | sed 's/^/CocoaPods /')" \
    || fallo "CocoaPods no instalado (brew install cocoapods)"
  command -v flutter >/dev/null 2>&1 && ok "$(flutter --version 2>/dev/null | head -1)" \
    || fallo "Flutter no está en el PATH"
  [ -f ios/Podfile.lock ] && ok "pods instalados (Podfile.lock)" \
    || aviso "sin ios/Podfile.lock: ejecuta 'cd ios && pod install'"
  [ -d ios/Runner.xcworkspace ] && ok "Runner.xcworkspace listo para abrir" \
    || aviso "Runner.xcworkspace no existe todavía (lo crea pod install)"
  [ -f ios/Flutter/Generated.xcconfig ] && ok "Generated.xcconfig presente" \
    || aviso "falta ios/Flutter/Generated.xcconfig: ejecuta 'flutter pub get'"
else
  aviso "no estás en macOS: aquí no se puede compilar para iPhone (Apple exige Xcode)"
fi

seccion "Resultado"
if [ "$fallos" -eq 0 ]; then
  printf "  %sTodo correcto%s (%s aviso(s)).\n" "$VERDE" "$FIN" "$avisos"
  cat <<'EOF'

  Siguiente paso:
    flutter pub get
    cd ios && pod install && cd ..
    open ios/Runner.xcworkspace
  En Xcode: target Runner > Signing & Capabilities > Team, y Run.
  Guía completa: docs/IPHONE.md
EOF
  exit 0
else
  printf "  %s%s problema(s) bloqueante(s)%s, %s aviso(s).\n" "$ROJO" "$fallos" "$FIN" "$avisos"
  exit 1
fi
