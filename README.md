# Pulso Basket

App móvil **Flutter** para jugadores de básquet: mide carrera y bicicleta con
GPS **sin datos móviles**, mantiene el registro con la **pantalla bloqueada**,
guarda el historial **para siempre en el teléfono** y guía una rutina semanal de
fuerza **solo con colchoneta** orientada a rendimiento en cancha.

> **Estado verificado:** `flutter analyze` sin incidencias, 8 tests en verde y
> `flutter build apk --debug` compilado correctamente con Flutter 3.24.5,
> AGP 8.3.2 y Kotlin 2.1.0 (código Dart + Kotlin + manifest).
>
> **iOS:** `ios/Runner.xcodeproj` está versionado y completo, con los dos targets
> (`Runner` y la extensión `PulsoWidget`), bundle ids, App Group y permisos de
> GPS en segundo plano ya cableados. No hay que crear nada a mano en Xcode: solo
> elegir *Team* y pulsar Run (**[docs/IPHONE.md](docs/IPHONE.md)**).
> La compilación iOS no se ejecutó en este entorno porque requiere macOS + Xcode;
> para validar la configuración antes de abrir Xcode está `./scripts/ios_check.sh`.

---

## 1. Qué hace

| Requisito | Implementación |
|---|---|
| GPS sin datos móviles | `geolocator` con `bestForNavigation`; no hay ninguna llamada de red en toda la app |
| Pantalla bloqueada | Android: servicio en primer plano + notificación con acciones. iOS: Live Activity + Dynamic Island |
| Widget en tiempo real | distancia, ritmo/velocidad, distancia restante, progreso y botones **Pausar / Reanudar / Detener** |
| Historial permanente | SQLite local (`sqflite`), sin cuentas ni nube |
| Gráficos de velocidad | media diaria de los últimos 7 días + perfil de velocidad de cada sesión |
| Rutina semanal | calendario editable con 4 días de fuerza y 3 de bici + 2 de carrera |
| Personalización | editor por día: título, tipo, distancia, nota y ejercicios (crear, editar, reordenar, borrar) |

---

## 2. Estructura del repositorio

```
pulso_basket/
├── lib/
│   ├── main.dart                     # arranque: fechas es, canal nativo, BD
│   ├── app.dart                      # tema Material 3 + navegación (5 pestañas)
│   ├── core/
│   │   ├── constants.dart            # canales nativos, App Group, umbrales GPS
│   │   ├── formatters.dart           # ritmo, distancia, duración en español
│   │   └── geo.dart                  # Haversine + DistanceFilter (anti-drift)
│   ├── data/
│   │   ├── app_database.dart         # esquema SQLite + siembra del plan
│   │   ├── providers.dart            # providers de Riverpod
│   │   ├── routine_seed.dart         # PLAN SEMANAL COMPLETO (ejercicios y pasos)
│   │   ├── session_repository.dart   # sesiones, puntos, estadísticas semanales
│   │   ├── routine_repository.dart   # lectura/escritura del calendario
│   │   └── models/                   # Exercise, RoutineDay, TrackPoint, WorkoutSession
│   ├── services/
│   │   ├── location_service.dart     # configuración de GPS en segundo plano
│   │   ├── tracking_controller.dart  # máquina de estados del entreno
│   │   └── lock_screen_service.dart  # puente con Android/iOS (comandos)
│   ├── features/
│   │   ├── home/                     # qué toca hoy + resumen semanal
│   │   ├── tracking/                 # grabación en vivo + traza GPS
│   │   ├── history/                  # historial + gráficos de velocidad
│   │   ├── routine/                  # calendario, detalle, editor
│   │   └── settings/                 # permisos, restaurar plan, borrar datos
│   └── widgets/                      # tarjetas, StatTile, pintor de ruta
├── android/app/src/main/
│   ├── AndroidManifest.xml           # permisos + servicio foregroundType=location
│   └── kotlin/com/pulso/basket/
│       ├── MainActivity.kt           # MethodChannel (Dart <-> nativo)
│       └── TrackingForegroundService.kt  # notificación de bloqueo + acciones
├── ios/
│   ├── Runner.xcodeproj/             # VERSIONADO: target Runner + target PulsoWidget
│   ├── Runner/
│   │   ├── AppDelegate.swift         # MethodChannel de Live Activity + deep links
│   │   ├── LiveActivityBridge.swift  # ActivityKit + App Group + polling 1 Hz
│   │   ├── PulsoActivityAttributes.swift  # compartido con la extensión
│   │   ├── PulsoCommandIntent.swift  # App Intents (Pausar/Reanudar/Detener)
│   │   ├── Runner.entitlements       # App Group
│   │   └── Assets.xcassets/          # iconos + launch screen
│   ├── PulsoWidget/                  # extensión WidgetKit (pantalla de bloqueo)
│   │   ├── PulsoWidgetBundle.swift   # @main de la extensión
│   │   ├── PulsoLiveActivityView.swift  # bloqueo + Dynamic Island
│   │   └── Info.plist / PulsoWidget.entitlements
│   └── Podfile
├── docs/
│   ├── IPHONE.md                     # guía iPhone paso a paso (empezar aquí)
│   ├── ARQUITECTURA.md               # decisiones técnicas y flujo de datos
│   ├── RUTINA.md                     # plan de 30 días, ejercicios y fuentes
│   ├── COMPILAR.md                   # Android, iOS y pantalla de bloqueo
│   └── GITHUB.md                     # publicar el repo, CI y releases
├── scripts/
│   ├── bootstrap.sh                  # genera el scaffolding nativo sin pisar el código
│   ├── ios_check.sh                  # 30 comprobaciones del proyecto iOS
│   └── parche_widget.py              # re-añade el target del widget al pbxproj
├── test/geo_test.dart                # tests de Haversine, filtro y formatos
└── .github/workflows/build.yml       # CI: analyze + test + APK
```

---

## 3. Empezar en 3 comandos

```bash
# Requisitos: Flutter 3.22+, Android Studio (Android) y Xcode 15+ (iOS)
cd pulso_basket
./scripts/bootstrap.sh     # crea iconos/storyboards/pbxproj que Flutter genera
flutter run                # dispositivo real conectado
```

`bootstrap.sh` ejecuta `flutter create` en una carpeta temporal y copia **solo
los archivos que faltan**. El manifest, Gradle, Kotlin, Swift y los plists de
este repo nunca se sobrescriben.

Compilar para distribuir:

```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Play Store
flutter build ipa --release        # iOS (requiere cuenta de desarrollador)
```

Detalle paso a paso y permisos: **[docs/COMPILAR.md](docs/COMPILAR.md)**.
Para iPhone, la guía corta y directa: **[docs/IPHONE.md](docs/IPHONE.md)**.

---

## 4. Cómo funciona el GPS con la pantalla bloqueada

```
Dart                          Nativo                        Sistema
─────────────────────────────────────────────────────────────────────────
TrackingController.start()
  ├─ crea fila en SQLite
  ├─ LockScreenService.start() ──► TrackingForegroundService (Android)
  │                                └─ startForeground(type=location)
  │                                   └─ notificación con 2 acciones
  └─ geolocator.getPositionStream(1 Hz, distanceFilter 2 m)
        │
        ├─ DistanceFilter: descarta precisión > 25 m y saltos > 60 m
        ├─ acumula metros (Haversine)
        ├─ cada 1 s  ──► notify() con distancia/ritmo/restante
        └─ cada 15 s ──► UPDATE sessions + INSERT track_points (lote)
```

* **Android**: el servicio en primer plano es obligatorio para recibir GPS con
  la pantalla apagada. La notificación es `ongoing`, `silent`,
  `VISIBILITY_PUBLIC` y `CATEGORY_WORKOUT`, con `PendingIntent`s que pausan,
  reanudan o detienen sin abrir la app.
* **iOS**: `allowBackgroundLocationUpdates: true` + `UIBackgroundModes:
  location`. La Live Activity muestra los mismos datos y sus botones usan
  `LiveActivityIntent` (iOS 17+), que escribe el comando en un **App Group**;
  el puente nativo lo lee a 1 Hz y lo entrega a Dart.
* Si el sistema mata el proceso, la sesión ya está en SQLite: no se pierde el
  recorrido (se guarda cada 15 s y en cada pausa).

Código clave:
[tracking_controller.dart](lib/services/tracking_controller.dart) ·
[location_service.dart](lib/services/location_service.dart) ·
[TrackingForegroundService.kt](android/app/src/main/kotlin/com/pulso/basket/TrackingForegroundService.kt) ·
[LiveActivityBridge.swift](ios/Runner/LiveActivityBridge.swift)

---

## 5. Rutina semanal

| Día | Sesión | Fuerza (≈30 min, colchoneta) |
|---|---|---|
| Lunes | 12 km bici | Espalda y dorsales (7 ejercicios) |
| Martes | 4 km carrera (GPS) | Pecho, bíceps y tríceps (8) |
| Miércoles | 12 km bici | — |
| Jueves | 4 km carrera (GPS) | Abdominales y core con rotación (8) |
| Viernes | 12 km bici | — |
| Sábado | 12 km bici | — |
| Domingo | Descanso / recuperación activa | — |

Pasos, corrección técnica y transferencia al básquet de cada ejercicio:
**[docs/RUTINA.md](docs/RUTINA.md)**. La fuente de verdad en código es
`lib/data/routine_seed.dart`, y todo es editable desde la app.

Referencias metodológicas (atribución de escuela, **no** afiliación): Dr. Stuart
McGill (Big 3 / estabilidad espinal), Mike Boyle (MBSC), EXOS–Mark Verstegen,
Peak Performance Project (Dr. Marcus Elliott), Tim Grover (Attack Athletics).

---

## 6. Privacidad

* No hay backend, ni login, ni analítica, ni publicidad.
* Los recorridos y los puntos GPS se guardan en `pulso_basket.db` dentro del
  teléfono y solo se borran desde Ajustes.
* La app no requiere conexión: si el teléfono está en modo avión, el GPS sigue
  funcionando.

---

## 7. Limitaciones honestas

1. **No hay mapa con calles offline.** Dibujar tiles sin red exige empaquetar
   MBTiles (cientos de MB) o un proveedor con caché. La app muestra la **traza
   GPS normalizada**, suficiente para ver forma, giros y calidad de señal.
2. **iOS < 17**: los botones de la Live Activity abren la app (deep link); el
   control sin abrirla requiere `LiveActivityIntent` (iOS 17+).
3. **Firmar requiere una cuenta Apple.** Compilar no: el workflow del repo
   compila el `.ipa` en un runner macOS de GitHub, y se instala en el iPhone con
   Sideloadly desde Windows (ver `docs/IPHONE.md` §6). Con Apple ID gratuito la
   app caduca a los 7 días y no hay App Groups (los botones abren la app en vez
   de actuar en segundo plano); con Mac + Xcode se firma igual pero con la
   misma limitación si la cuenta es gratuita.
4. **Fabricantes agresivos** (Xiaomi/Oppo/Samsung) pueden matar el servicio:
   hay que excluir la app de la optimización de batería.
5. La rutina es un plan de entrenamiento, no un tratamiento médico.

---

## 8. Licencia

MIT. Úsalo, modifícalo y publícalo; conserva el aviso de licencia.
