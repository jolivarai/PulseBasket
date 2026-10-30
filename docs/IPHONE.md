# Pulso Basket en iPhone — guía definitiva

El proyecto iOS está **completo y versionado** en el repo. No hay que crear
ningún target a mano: la app (`Runner`) y la extensión del widget
(`PulsoWidget`) ya están en `ios/Runner.xcodeproj`, con bundle ids, App Group,
entitlements, permisos de GPS en segundo plano e iconos.

Lo único que no se puede automatizar es **firmar con tu Apple ID**: eso ocurre
en Xcode, en tu Mac, la primera vez.

```
Ya hecho en el repo
  ios/Runner.xcodeproj   target Runner + target PulsoWidget (Live Activity)
  bundle ids             com.pulso.basket  /  com.pulso.basket.PulsoWidget
  App Group              group.com.pulso.basket en la app y en el widget
  permisos               UIBackgroundModes=location (GPS con pantalla apagada)
  Live Activities        NSSupportsLiveActivities + FrequentUpdates
  esquema pulso://       botones también en iOS 16.1-16.4
  recursos               iconos de app, launch screen, entitlements
```

| Comprobación rápida | Comando |
|---|---|
| ¿Está todo bien configurado? | `./scripts/ios_check.sh` |
| ¿Compila Dart? | `flutter analyze && flutter test` |

---

## 0. Antes de empezar: ¿tienes un Mac?

Apple **no permite** compilar iOS desde Windows ni Linux… pero **no necesitas
compilar**: el workflow del repo ya lo hace en un runner macOS de GitHub y te
deja un `.ipa` listo para instalar con Sideloadly. macOS con Xcode solo es
obligatorio si quieres firmar tú mismo desde Xcode.

| Tu situación | Camino |
|---|---|
| **Windows o Linux, sin Mac** | GitHub Actions compila el `.ipa` (job `ios`) y **Sideloadly** lo instala por cable con tu Apple ID gratis → **sección 6**. Sin Mac, sin cuenta de pago. |
| Mac con macOS 13 o superior | Sigue esta guía desde la sección 1. 20–30 min la primera vez. |
| Windows / Linux, instalación permanente | Mac alquilado por horas (**MacinCloud**, **MacStadium**) o TestFlight con cuenta de pago. |
| Solo quiero probarlo unos días | Sideloadly (7 días) o Mac + Apple ID gratuito (7 días). |

### Cuenta de Apple: lo que cambia

| | Apple ID gratis | Apple Developer Program (99 USD/año) |
|---|---|---|
| Instalar en tu iPhone | Sí, 7 días por instalación | Sí, sin límite |
| App Groups (botones sin abrir la app) | **No** | Sí |
| TestFlight / App Store | No | Sí |
| Caducidad | 7 días | 1 año (TestFlight: 90 días por build) |

Con cuenta gratuita la app **compila igual**: hay que quitar la capability
*App Groups* de los dos targets (paso 3.1) y los botones del widget pasan a
abrir la app con un toque (`pulso://`). Todo lo demás (GPS en segundo plano,
historial, gráficos, rutina) funciona sin cambios.

---

## 1. Preparar el Mac (una sola vez)

```bash
# 1. Xcode desde la App Store (gratis, ~10 GB). Después:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# 2. Flutter y CocoaPods
brew install --cask flutter
brew install cocoapods
flutter doctor -v        # "Xcode" y "CocoaPods" deben salir en verde
```

En el iPhone:

1. **Ajustes > Privacidad y seguridad > Modo desarrollador** → activar →
   reiniciar el teléfono (obligatorio desde iOS 16).
2. Conecta el iPhone por cable y pulsa **Confiar** en el teléfono.

---

## 2. Compilar y ejecutar

```bash
cd pulso_basket
flutter pub get                 # genera ios/Flutter/Generated.xcconfig
./scripts/ios_check.sh          # comprueba la configuración; debe decir "Todo correcto"
cd ios && pod install && cd ..
open ios/Runner.xcworkspace     # SIEMPRE el .xcworkspace, nunca el .xcodeproj
```

En Xcode:

1. Panel izquierdo, arriba: selecciona el proyecto **Runner**.
2. Target **Runner** > pestaña **Signing & Capabilities**:
   - **Team** → tu Apple ID (si no aparece: *Add an Account…*).
   - **Bundle Identifier** → uno único, p. ej. `com.tunombre.pulsobasket`.
   - Deja **Automatically manage signing** marcado.
3. Target **PulsoWidget** > **Signing & Capabilities**:
   - **Team** → el mismo.
   - **Bundle Identifier** → el de Runner + `.PulsoWidget`
     (p. ej. `com.tunombre.pulsobasket.PulsoWidget`).
4. Arriba, en la barra de esquemas: elige tu iPhone (no un simulador) y pulsa
   **Run** (▶).

Primera vez en el teléfono: **Ajustes > General > VPN y gestión de dispositivos
> tu Apple ID > Confiar**. Sin esto la app no arranca ("Untrusted Developer").

> El simulador **no sirve** para probar esto: no tiene GPS real ni Live
> Activities. Usa siempre un iPhone físico.

---

## 3. Ajustes según tu cuenta

### 3.1 Cuenta gratuita: quitar App Groups

Xcode fallará al firmar con un mensaje del tipo *"Personal development teams do
not support the App Groups capability"*.

1. Target **Runner** > **Signing & Capabilities** > selecciona **App Groups** >
   botón **−** (eliminar).
2. Lo mismo en **PulsoWidget**.
3. Run otra vez.

Consecuencia: los botones del widget ya no pausan en segundo plano; abren la app
(un toque) y allí se aplica el comando al instante. El resto del widget
(distancia, ritmo, restante, barra de progreso) funciona igual.

### 3.2 Cuenta de pago: no toques nada

El App Group `group.com.pulso.basket` ya está en los dos entitlements; Xcode lo
registra solo en el portal al firmar.

---

## 4. Permisos dentro de la app

La app solo pide **un** permiso: ubicación.

1. **Ubicación** → **Permitir siempre**. Si eliges "Al usar la app", el propio
   código te avisa y no deja empezar: iOS corta el GPS al bloquear.
2. Si el sistema pregunta "¿Permitir que Pulso Basket use tu ubicación en
   segundo plano?" → **Permitir siempre**.

Verifica después:

* **Ajustes > Privacidad y seguridad > Localización > Pulso Basket > Siempre**.
* **Ajustes > Pulso Basket > Actividades en vivo** → activado (lo está por
  defecto; si lo desactivas, no aparece el widget de bloqueo).
* **Ajustes > Batería > Modo de bajo consumo** → desactívalo mientras entrenas:
  con él, iOS reduce la frecuencia del GPS.

---

## 5. Probar la pantalla de bloqueo

1. Pestaña **Entrenar** > **Iniciar**.
2. Bloquea el iPhone.
3. Aparece la Live Activity con distancia, ritmo/velocidad, distancia restante,
   barra de progreso y los botones **Pausar / Reanudar / Detener**.
4. **iOS 17+**: los botones actúan sin abrir la app (App Intent + App Group).
   **iOS 16.1–16.4**: el botón abre la app y aplica el comando (no existen
   botones interactivos en Live Activities antes de iOS 17).
5. En iPhone 14 Pro o superior también se ve en la **Dynamic Island**.

Prueba de fondo real: inicia un entreno, bloquea el teléfono, camina 200 m y
comprueba que la distancia sube **sin datos móviles** (modo avión + WiFi
apagado). Al terminar, la sesión queda en **Historial**.

---

## 6. Sin Mac: instalar con Sideloadly

El único camino que **no necesita macOS**. Sideloadly firma el `.ipa` con tu
Apple ID desde Windows (o Mac) y lo instala por cable.

Consecuencia: los botones del widget funcionan, pero **abren la app** (sin App
Group no hay forma de que el widget escriba en la app).

### 6.1 Descargar el `.ipa`

GitHub > **Actions** > último run *Build & test* > job **ios** > sección
**Artifacts** > descarga **`pulso-basket-ipa-unsigned`** y descomprímelo.
Dentro está `Pulso-Basket-unsigned.ipa`.

### 6.2 Preparar la computadora

| Requisito | Detalle |
|---|---|
| Windows 7+ o macOS 10.12+ | |
| **iTunes "web"**, no el de Microsoft Store | [apple.com/itunes/download/win64](https://www.apple.com/itunes/download/win64). Si tienes el de la Store, desinstálalo antes |
| **iCloud "web"** (solo Windows) | [iCloudSetup.exe](https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe) |
| Sideloadly | [sideloadly.io](https://sideloadly.io/) |
| Cable y iPhone desbloqueado | Pulsa **Confiar** cuando pregunte |

### 6.3 Instalar

1. Conecta el iPhone y abre Sideloadly (el dispositivo aparece arriba).
2. Arrastra `Pulso-Basket-unsigned.ipa` a la ventana.
3. **Apple ID**: tu correo. Contraseña: la de la cuenta (solo se usa para pedir
   el certificado a Apple; con 2FA, escribe el código cuando lo pida).
4. Pulsa **Start**. Tarda 1–3 minutos.
5. En el iPhone: **Ajustes > General > VPN y gestión de dispositivos > tu Apple
   ID > Confiar**.
6. Abre la app y concede **Ubicación: Permitir siempre**.

### 6.4 Límites del Apple ID gratis

| Límite | Valor |
|---|---|
| Duración de la app instalada | **7 días** (después deja de abrir) |
| Apps activas a la vez | 3 |
| App IDs nuevos por semana | 10 (esta app usa 2: app y widget) |

Sideloadly tiene **auto-refresh**: re-firma sola la app antes de que caduque,
si dejas la computadora encendida con el programa abierto. Si no, repites el
paso 6.3 cada 7 días. Ojo: al reinstalar, iOS puede borrar los datos de la app
(historial incluido); para uso serio, TestFlight o Mac.

### 6.5 Si falla

| Error | Solución |
|---|---|
| `signed with invalid entitlements` | Marca **Remove Extensions** en Sideloadly (pierdes el widget, la app funciona) |
| `Unable to install` | Desbloquea el iPhone, acepta "Confiar", prueba otro cable o un puerto USB 2.0 |
| `AMFI: code signature invalid` | Borra la app del teléfono y reinstala |
| Se instala y se cierra sola | El `.ipa` quedó incompleto: descárgalo de nuevo |
| `integrity could not be verified` | Falta confiar en el desarrollador (paso 5) |

---

## 7. Instalarlo de forma permanente

| Método | Requisitos | Duración |
|---|---|---|
| Cable + cuenta gratis | Apple ID gratis | 7 días, hay que reinstalar |
| **TestFlight** | Developer Program | 90 días por build, 100 testers |
| App Store | Developer Program + revisión | Permanente |

```bash
flutter build ipa --release
open build/ios/archive/Runner.xcarchive     # o Xcode > Product > Archive
```

Sube el `.ipa` con **Transporter** (gratis en la Mac App Store) o con Xcode
Organizer, espera el procesado (5–30 min) y reparte el enlace desde App Store
Connect > TestFlight.

> Ojo con las versiones: el widget tiene `MARKETING_VERSION = 1.0.0` y
> `CURRENT_PROJECT_VERSION = 1` fijos en el pbxproj, porque no hereda el
> `Generated.xcconfig` de Flutter. Si subes la versión en `pubspec.yaml`,
> cámbialas también en el target **PulsoWidget > General > Identity** (deben
> coincidir con la app o App Store Connect rechaza el build).

---

## 8. Problemas típicos

| Síntoma | Causa / solución |
|---|---|
| `No signing certificate found` | Falta elegir Team o el bundle id ya está usado por otra app |
| `Unable to install "Runner"` | Confía en el desarrollador: Ajustes > General > VPN y gestión de dispositivos |
| `Personal development teams do not support App Groups` | Quita la capability App Groups (paso 3.1) |
| La Live Activity no aparece | iOS 16.1+, *Actividades en vivo* activadas, y el target `PulsoWidget` compilado (Run compila también la extensión) |
| Los botones no hacen nada | Cuenta gratis sin App Groups (abren la app) o `PulsoActivityAttributes.swift` fuera del target del widget |
| El GPS se corta al bloquear | Permiso "Siempre" + desactivar el ahorro de energía para la app |
| `pod install` falla | `brew install cocoapods && pod repo update` |
| `flutter pub get` no genera `Generated.xcconfig` | Estás en la carpeta `ios/`: ejecútalo desde la raíz del proyecto |
| Build falla con "Unable to boot simulator" | No uses simulador para este proyecto: elige el iPhone físico |
| Xcode dice "Failed to prepare device" | Reinicia el iPhone, cambia el cable, confía de nuevo |

---

## 9. Resumen

**Ruta A — sin Mac (Sideloadly):**

1. Sube el repo a GitHub y espera el job `ios` en **Actions**.
2. Descarga el artifact `pulso-basket-ipa-unsigned`.
3. Sideloadly + iTunes web en Windows → arrastra el `.ipa` → Apple ID → Start.
4. Confiar en el desarrollador y dar Ubicación **Siempre**.
5. Repetir cada 7 días (o dejar el auto-refresh activo).

**Ruta B — con Mac (permanente / TestFlight):**

1. Mac + Xcode + Flutter + CocoaPods.
2. `flutter pub get` → `./scripts/ios_check.sh` → `cd ios && pod install`.
3. `open ios/Runner.xcworkspace`.
4. Team + bundle id único en **Runner** y en **PulsoWidget** → Run.
5. Confiar en el desarrollador; Ubicación **Siempre**.
6. Para uso continuo: `flutter build ipa --release` → TestFlight.

Detalle de la arquitectura interna (puente nativo, App Group, por qué hay
sondeo a 1 Hz): [`ARQUITECTURA.md`](ARQUITECTURA.md).
