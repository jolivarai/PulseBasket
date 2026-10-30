# Arquitectura y decisiones técnicas

## Capas

```
┌──────────────────────────── UI (Flutter) ────────────────────────────┐
│ Home · Tracking · History · Routine · Settings                      │
│                       Riverpod (Notifier / FutureProvider)           │
└───────────────┬───────────────────────────────┬─────────────────────┘
                │                               │
        ┌───────▼────────┐              ┌───────▼─────────┐
        │ TrackingController │           │ Repositorios    │
        │ (máquina de estados)│          │ Session / Routine│
        └───┬────────┬───┘              └───────┬─────────┘
            │        │                          │
   ┌────────▼──┐  ┌──▼──────────────┐    ┌──────▼──────┐
   │Location   │  │LockScreenService│    │ SQLite      │
   │Service    │  │(MethodChannel)  │    │ sqflite     │
   └────┬──────┘  └──┬───────────┬──┘    └─────────────┘
        │            │           │
   geolocator   Android FGS   iOS Live Activity
```

## Decisiones y por qué

### 1. Un solo servicio en primer plano en Android
`geolocator` puede crear su propia notificación
(`foregroundNotificationConfig`), pero entonces habría **dos** notificaciones y
ninguna con botones. Se desactiva la del plugin y se usa
`TrackingForegroundService` como única superficie: mantiene el proceso vivo y
es la pantalla de bloqueo.

### 2. La notificación no calcula nada
Dart envía cada segundo textos ya formateados (`"3,4 km"`, `"5'32\""`). Si Kotlin
formateara, habría dos implementaciones del ritmo y dos oportunidades de
divergir. La UI nativa es tonta a propósito.

### 3. `DistanceFilter` propio
Tres defensas contra la distancia inflada:

1. `accuracy > 25 m` → punto descartado.
2. desplazamiento `< 2,5 m` → no suma (ruido de GPS parado).
3. salto `> 60 m` en un segundo → se ignora (salto de celda, no sprint).
4. media móvil exponencial (α = 0,35) para el ritmo mostrado.

Sin esto, un entreno de 40 min parado puede "ganar" 300–800 m.

### 4. Persistencia incremental
La fila de `sessions` se crea **antes** del primer punto GPS y se actualiza cada
15 s; los puntos se insertan por lotes de 15. Si el proceso muere, se conserva
casi todo. El coste de escribir 1 fila/s durante 40 min sería absurdo en disco y
batería.

### 5. Rutina como JSON en SQLite
`routine_days(weekday, payload)` evita migraciones cada vez que se añade un campo
a un ejercicio. El plan se siembra la primera vez desde `kSeedWeek` y se puede
restaurar desde Ajustes.

### 6. Riverpod sin generadores
`Notifier` + `FutureProvider` cubre el 100 % de la app sin `build_runner`, lo que
hace el repo clonable y compilable sin pasos de codegen.

### 7. Traza GPS en vez de mapa
Sin red no hay tiles. Un `CustomPainter` normaliza lat/lng y dibuja la ruta; el
peso es cero y funciona en modo avión.

## Esquema de base de datos

```sql
sessions(
  id INTEGER PK, title TEXT, type TEXT, started_at INTEGER, finished_at INTEGER,
  distance_m REAL, moving_s INTEGER, target_m REAL,
  avg_speed REAL, max_speed REAL, is_finished INTEGER,
  notes TEXT, weekday_plan INTEGER
)
track_points(
  id INTEGER PK, session_id INTEGER FK → sessions(id) ON DELETE CASCADE,
  lat REAL, lng REAL, speed REAL, altitude REAL, accuracy REAL,
  ts INTEGER, distance_so_far REAL
)
routine_days(weekday INTEGER PK, payload TEXT)  -- JSON de RoutineDay
```

Índices: `(session_id, ts)` para los gráficos y `(started_at)` para el historial.

## Estados del entrenamiento

```
idle ──start()──► acquiring ──primer fix──► running
                     │                        │  ▲
                     │                        │  │ resume()
                     │                     pause()
                     │                        ▼  │
                     └────────────────────► paused
running/paused ──finish()──► finished ──reset()──► idle
```

Los comandos de la pantalla de bloqueo (`pause`, `resume`, `stop`) entran al
mismo controlador, así que la lógica es idéntica venga de donde venga.

## Compatibilidad

| Plataforma | Mínimo | Notas |
|---|---|---|
| Android | API 23 (6.0) | FGS tipo `location` obligatorio desde API 29; permiso notificaciones desde API 33 |
| iOS | 13.0 (app) / 16.1 (Live Activity) | botones sin abrir la app: iOS 17+ |

## Deuda técnica conocida

* No hay mapa con calles offline (ver README §7).
* `todayPlanProvider` no se refresca solo a medianoche; se invalida al editar y
  al volver a Inicio (mejora trivial con un `Timer` de 1 min).
* El editor no permite duplicar un día completo (solo ejercicios uno a uno).
* No hay exportación GPX/CSV todavía; el esquema ya guarda todo lo necesario.
