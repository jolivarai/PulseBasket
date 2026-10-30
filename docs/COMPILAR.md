# Compilar y probar

## 0. Requisitos

| Herramienta | Versión | Verificar con |
|---|---|---|
| Flutter | 3.22 o superior (recomendado 3.24/3.27) | `flutter --version` |
| Dart | incluido con Flutter | `dart --version` |
| Java JDK | 17 | `java -version` |
| Android SDK | API 34 | Android Studio > SDK Manager |
| Xcode (solo iOS/macOS) | 15+ | `xcodebuild -version` |
| CocoaPods | 1.14+ | `pod --version` |

```bash
flutter doctor -v      # debe estar todo en verde (iOS solo en macOS)
```

### Toolchain con el que se verificó este repo

| Pieza | Versión |
|---|---|
| Flutter | 3.24.5 (stable) |
| Dart | 3.5.x |
| AGP | 8.3.2 |
| Kotlin | 2.1.0 |
| Gradle | 8.4 |
| JDK | 17 (Temurin) |
| compileSdk / targetSdk | 34 |
| minSdk | 23 |

Con esa combinación: `flutter analyze` sin incidencias, `flutter test` 8/8 y
`flutter build apk --debug` correcto.

> **Nota sobre Gradle y plugins.** Varios plugins (geolocator, sqflite,
> package_info_plus) leen `flutter.compileSdkVersion` dentro de su propio
> `android {}`. En Gradle 8 + AGP 8 esa extensión solo existe en `:app`, así que
> `android/build.gradle` publica esos valores como propiedades extra en los
> demás subproyectos. Si tu toolchain ya los expone, los valores coinciden y no
> cambia nada; no lo borres salvo que actualices todos los plugins.
>
> Si el build se queda sin memoria en un contenedor/CI, `gradle.properties` ya
> limita Gradle a 2 GB y el daemon de Kotlin a 1 GB. Súbelo solo si tu máquina
> tiene más de 8 GB.

## 1. Preparar el proyecto

```bash
cd pulso_basket
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

Esto genera lo que Flutter crea automáticamente y que no tiene sentido
versionar a mano: iconos `mipmap`, `LaunchScreen.storyboard`,
`project.pbxproj`, `gradle wrapper`, `Generated.xcconfig`… y **no sobrescribe**
el código del repo (`rsync --ignore-existing`).

## 2. Android

### Compilar y ejecutar

```bash
flutter run                                  # dispositivo o emulador
flutter build apk --release                  # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release            # build/app/outputs/bundle/release/app-release.aab
```

> Para Play Store necesitas tu propio keystore (`docs/GITHUB.md` §4). El
> `build.gradle` del repo firma con la clave de depuración para que `--release`
> funcione sin configuración.

### Permisos que verás al abrir por primera vez

1. **Ubicación** → "Mientras uso la app" (Android 10) o "Permitir siempre".
2. **Ubicación en segundo plano** → "Permitir siempre". Sin esto el sistema
   corta el GPS al bloquear la pantalla.
3. **Notificaciones** (Android 13+) → permitir: es la pantalla de bloqueo.

Si denegaste algo: Ajustes del teléfono > Apps > Pulso Basket > Permisos.

### Excluir de la optimización de batería

Fabricantes como Xiaomi, Oppo, vivo o Samsung matan servicios en segundo plano:

* **Xiaomi**: Ajustes > Batería > Sin restricciones + "Inicio automático".
* **Samsung**: Ajustes > Batería > Límites de uso en segundo plano > Nunca.
* **Oppo/Realme**: Ajustes > Batería > Optimización > Pulso Basket > No optimizar.

### Probar la pantalla de bloqueo

1. Pulsa **Entrenar** > **Iniciar entrenamiento**.
2. Bloquea el teléfono.
3. Debe aparecer la notificación "Pulso Basket · GRABANDO" con distancia,
   ritmo y los botones **Pausar** y **Detener**.
4. Pulsa **Pausar** → el estado cambia a PAUSADO y el cronómetro se detiene.
5. Desbloquea: la app debe reflejar el mismo estado (mismo controlador).

En algunos fabricantes hay que **expandir** la notificación para ver los
botones, y en Ajustes > Pantalla de bloqueo > "Mostrar contenido sensible" debe
estar permitido.

### Servicio en primer plano: lo que Android 14 exige

Ya está declarado en el manifest:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<service android:name=".TrackingForegroundService"
         android:foregroundServiceType="location" ... />
```

Y en Kotlin se arranca con `ServiceCompat.startForeground(..., FOREGROUND_SERVICE_TYPE_LOCATION)`.
Si añades otro tipo de servicio, revisa la política de Play Store.

## 3. iOS (solo macOS)

> Guía completa, con capturas de qué tocar en Xcode y qué hacer según tengas
> cuenta Apple gratuita o de pago: **[`IPHONE.md`](IPHONE.md)**.

### 3.1 Estado del proyecto iOS

`ios/Runner.xcodeproj` está **versionado y completo**:

| Elemento | Valor |
|---|---|
| Target de la app | `Runner` — `com.pulso.basket` |
| Target del widget | `PulsoWidget` — `com.pulso.basket.PulsoWidget` (extensión WidgetKit) |
| Deployment target | app iOS 13.0 · widget iOS 16.1 (Live Activities) |
| App Group | `group.com.pulso.basket` en los dos entitlements |
| Permisos | `UIBackgroundModes=location`, `NSSupportsLiveActivities(FrequentUpdates)`, textos de ubicación |
| Recursos | iconos de app, launch screen naranja, esquema `pulso://` |

No hay que crear ningún target a mano.

### 3.2 Compilar

```bash
flutter pub get                 # genera Flutter/Generated.xcconfig
./scripts/ios_check.sh          # valida toda la configuración antes de abrir Xcode
cd ios && pod install && cd ..
open ios/Runner.xcworkspace     # siempre el .xcworkspace
```

### 3.3 Firma (único paso manual)

En Xcode, **target Runner** y **target PulsoWidget**:

* **Team**: tu Apple ID / equipo.
* **Bundle Identifier**: uno único; el del widget debe ser el de la app +
  `.PulsoWidget` (p. ej. `com.tunombre.pulsobasket.PulsoWidget`).

Con cuenta gratuita, elimina la capability **App Groups** en ambos targets
(Apple no la soporta en equipos personales). Los botones del widget pasan a
abrir la app con `pulso://`, que es el fallback ya implementado.

### 3.4 Permisos en el iPhone

`Info.plist` ya incluye:

```xml
<key>UIBackgroundModes</key><array><string>location</string></array>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>…
<key>NSSupportsLiveActivities</key><true/>
```

Al abrir la app: permitir ubicación **"Siempre"**. Si solo diste "Al usar la
app", la app te lo dirá y no arrancará el entreno (es deliberado: sin "Siempre"
iOS pausa el GPS al bloquear).

### 3.5 Probar

```bash
flutter run --release      # en iPhone real, no en simulador
```

1. Iniciar entreno → bloquear → la Live Activity aparece en la pantalla de
   bloqueo y en la Dynamic Island.
2. iOS 17+: **Pausar/Reanudar** funciona sin abrir la app (App Intent + App
   Group).
3. iOS 16.1–16.4: el botón abre la app con `pulso://pause` y allí se aplica.
4. `flutter build ipa --release` para TestFlight/App Store.

> El simulador no tiene GPS real ni Live Activities: estas funciones solo se
> validan en un iPhone físico.
>
> Si alguien devuelve el `project.pbxproj` al estado de `flutter create`, el
> target del widget se re-añade con `python3 scripts/parche_widget.py` y se
> verifica con `python3 scripts/parche_widget.py --check`.

## 4. Tests y análisis

```bash
flutter analyze
flutter test
```

`test/geo_test.dart` cubre Haversine, el filtro anti-drift y los formatos de
ritmo/distancia.

## 5. Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| La notificación no aparece | Falta permiso de notificaciones (Android 13+) o el canal está silenciado |
| El GPS se corta al bloquear | Permiso "Siempre" + exclusión de batería |
| `MissingPluginException` | `flutter pub get` y recompilar; el canal solo existe en build nativo |
| La Live Activity no aparece | `NSSupportsLiveActivities`, target `PulsoWidget` presente (`./scripts/ios_check.sh`), Actividades en vivo activadas en Ajustes |
| Botones del widget no responden (iOS 16) | Es el comportamiento documentado: abren la app |
| `Podfile` error de deployment target | `pod install --repo-update` |
| Build Android falla por `minSdk` | Asegura `minSdk = 23` (ya está en `build.gradle`) |
| Aviso de NDK de los plugins | Es informativo si no hay código nativo; para silenciarlo fija `ndkVersion` en `android/app/build.gradle` |
| `Daemon disappeared` / OOM | Baja `org.gradle.jvmargs` y `kotlin.daemon.jvmargs` en `android/gradle.properties` |
