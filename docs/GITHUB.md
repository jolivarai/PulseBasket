# Subir Pulso Basket a GitHub — paso a paso

Guía pensada para hacerlo una vez, desde cero, sin experiencia previa con git.
Tiempo: 10–15 minutos.

---

## 0. Antes de empezar

| Necesitas | Cómo se comprueba |
|---|---|
| Cuenta de GitHub (gratis) | [github.com/signup](https://github.com/signup) |
| git instalado | `git --version` (en Windows: instala **Git for Windows**, incluye Git Bash) |
| La carpeta del proyecto descomprimida | `pulso_basket/` con `pubspec.yaml`, `lib/`, `ios/`, `android/` dentro |

> El proyecto ya trae `.gitignore` preparado: **no** se suben `build/`,
> `.dart_tool/`, `ios/Pods/`, ni ningún keystore o contraseña. En total son
> 102 archivos, unos 750 KB.

Decide ahora la visibilidad del repositorio:

* **Public** → los minutos del runner macOS de GitHub Actions son **gratis**
  (te compila también la app de iPhone). Recomendado.
* **Private** → el código no se ve, pero los minutos de macOS se descuentan de
  tu cuota (se multiplican ×10).

---

## 1. Crear el repositorio vacío en GitHub

1. Entra en [github.com/new](https://github.com/new).
2. **Repository name**: `pulso-basket`.
3. **Description** (opcional): `GPS offline + rutina de fuerza para básquet (Flutter)`.
4. Marca **Public** (o Private).
5. **No marques** nada más: sin README, sin `.gitignore`, sin licencia. El
   proyecto ya los trae; si GitHub los crea, el primer push choca.
6. **Create repository**.

Verás una pantalla con comandos. Los usaremos en el paso 4.

---

## 2. Abrir la terminal en la carpeta del proyecto

| Sistema | Cómo |
|---|---|
| Windows | Clic derecho en la carpeta `pulso_basket` > **Abrir en Terminal** (o Git Bash) |
| macOS | Clic derecho > **Servicios > Nueva terminal en la carpeta**, o `cd` a mano |
| Linux | `cd ~/Descargas/pulso_basket` |

Comprueba que estás en el sitio correcto:

```bash
ls
# Deben aparecer: README.md  android  docs  ios  lib  pubspec.yaml  scripts  test
```

Todos los comandos siguientes se ejecutan ahí dentro.

---

## 3. Identificarte en git (una sola vez por computadora)

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo@ejemplo.com"
```

Usa el **mismo correo de tu cuenta de GitHub** para que los commits aparezcan
a tu nombre.

---

## 4. Crear el repositorio local y el primer commit

```bash
git init
git add .
git commit -m "feat: Pulso Basket, GPS offline + rutina de fuerza para basquet"
```

`git add .` prepara todo lo que no esté ignorado. Puedes revisar qué se va a
subir antes de confirmar:

```bash
git status --short | wc -l     # 102 archivos
git ls-files | head            # lista de archivos versionados
```

Si aparece `android/key.properties`, `*.jks` o `ios/Pods/`, algo se desactivó
en `.gitignore`: no sigas, revísalo.

---

## 5. Conectar con GitHub y subir

```bash
git branch -M main
git remote add origin https://github.com/TU_USUARIO/pulso-basket.git
git push -u origin main
```

Cambia `TU_USUARIO` por tu usuario real.

### Si te pide contraseña

GitHub **no acepta la contraseña de la cuenta** por HTTPS. Necesitas un token:

1. [github.com/settings/tokens](https://github.com/settings/tokens) >
   **Generate new token (classic)**.
2. Note: `pulso-basket`; Expiration: 90 días; Scope: marca **`repo`**.
3. **Generate token** y copia el valor (`ghp_...`): solo se muestra una vez.
4. En el `push`, cuando pida **Password**, pega el token (no la contraseña).

Para no repetirlo:

```bash
# macOS
git config --global credential.helper osxkeychain
# Windows
git config --global credential.helper manager
# Linux
git config --global credential.helper store
```

### Alternativa: SSH (si ya tienes clave)

```bash
ssh-keygen -t ed25519 -C "tu-correo@ejemplo.com"     # si no tienes
cat ~/.ssh/id_ed25519.pub                            # pega esto en GitHub > Settings > SSH keys
git remote set-url origin git@github.com:TU_USUARIO/pulso-basket.git
git push -u origin main
```

---

## 6. Verificar que subió bien

1. Recarga la página del repositorio: deben verse `lib/`, `ios/`, `android/`,
   `docs/`, `README.md` y el badge de commits.
2. **No** deben verse `build/`, `.dart_tool/`, `Pods/` ni keystores.
3. Pestaña **Actions**: se dispara solo el workflow *Build & test* con 3 jobs:
   - `analyze-and-test` (2–3 min)
   - `apk` (5–8 min)
   - `ios` (8–12 min, corre en macOS y compila app + extensión del widget)

Si `ios` sale en verde, el proyecto Xcode compila correctamente aunque tú no
tengas un Mac.

Artefactos descargables al final de cada job, en la parte de abajo de la página
del run (**Artifacts**):

| Artefacto | Para qué |
|---|---|
| `pulso-basket-apk` | instalar en Android |
| `pulso-basket-ipa-unsigned` | instalar en iPhone con **Sideloadly** (ver `IPHONE.md` §6) |
| `pulso-basket-ios-unsigned` | inspeccionar el `.app` y la extensión `PulsoWidget.appex` |

---

## 7. Publicar una versión (opcional)

```bash
git tag -a v1.0.0 -m "Pulso Basket 1.0.0"
git push origin v1.0.0
```

En GitHub: **Releases > Draft a new release** > elige el tag `v1.0.0` >
**Generate release notes** > adjunta el APK descargado de Actions > **Publish**.

---

## 8. Trabajo del día a día

```bash
git status                    # qué cambió
git add .                     # preparar todo
git commit -m "fix: corrige el ritmo cuando hay pausa"
git push                      # ya sabe a dónde ir
```

Si trabajas en otra computadora:

```bash
git pull                      # traer cambios antes de tocar nada
```

Convención de mensajes:

```
feat:     nueva funcionalidad
fix:      corrección de bug
docs:     documentación
refactor: cambio interno sin cambio de comportamiento
test:     tests
chore:    tooling, dependencias
```

---

## 9. Alternativa sin terminal: GitHub Desktop

1. Instala [GitHub Desktop](https://desktop.github.com/).
2. **File > Add local repository…** > elige la carpeta `pulso_basket`.
3. Si dice que no es un repositorio, **create a repository** ahí mismo, nombre
   `pulso-basket`.
4. Escribe el resumen del commit > **Commit to main** > **Publish repository**
   (desmarca *Keep this code private* si quieres el CI de macOS gratis).

Hace exactamente lo mismo que los pasos 4–5, con botones.

---

## 10. Qué se sube y qué no

`.gitignore` ya excluye:

* `build/`, `.dart_tool/`, `.flutter-plugins*`, `*.iml`, `.idea/`, `.vscode/`
* `android/local.properties`, `android/key.properties`, `*.jks`, `*.keystore`
* `ios/Pods/`, `**/xcuserdata/`, `ios/Flutter/ephemeral/`,
  `ios/Flutter/Generated.xcconfig` (se regenera con `flutter pub get`)
* `*.pbxproj.bak` y el `GeneratedPluginRegistrant.java` de Android

**Sí** se sube `pubspec.lock`: es una app, no un paquete, y el lock fija las
versiones exactas para que compile igual en tu Mac y en el CI.

**Nunca** subas `android/key.properties` ni tu `.jks`: son credenciales de
firma. Si ya los subiste por error, cámbialos de sitio y considera el keystore
comprometido.

Lo que **sí** debe estar: `lib/`, `android/app/src/main/**`, `ios/Runner/**`,
`ios/PulsoWidget/**`, `ios/Runner.xcodeproj/project.pbxproj`, `docs/`, `test/`,
`scripts/`, `.github/workflows/`.

---

## 11. CI incluida

`.github/workflows/build.yml` se ejecuta en cada push a `main`:

1. `flutter analyze`
2. `flutter test`
3. `flutter build apk --release` → artefacto `pulso-basket-apk`
4. **Job `ios` (runner macOS)**: `scripts/ios_check.sh` + `flutter build ios
   --release --no-codesign` → artefactos `pulso-basket-ios-unsigned` (el `.app`)
   y **`pulso-basket-ipa-unsigned`** (el `.ipa` listo para Sideloadly/AltStore)

El job de iOS es la forma de comprobar que el proyecto Xcode y la extensión
`PulsoWidget` compilan **sin tener un Mac**: si ese job pasa, el proyecto
también compila en Xcode. En repositorios públicos los minutos de macOS son
gratis; en privados se descuentan de tu cuota (multiplicador ×10).

---

## 12. Firma de release (Android)

Solo si vas a publicar en Play Store.

```bash
keytool -genkey -v -keystore ~/pulso-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` (fuera del repo):

```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=upload
storeFile=/ruta/absoluta/pulso-upload.jks
```

Y en `android/app/build.gradle`, sustituye `signingConfig = signingConfigs.debug`
por la lectura de ese archivo. En GitHub Actions, guárdalo como secretos
(**Settings > Secrets and variables > Actions**):

| Secret | Contenido |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 pulso-upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | contraseña del store |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | contraseña de la key |

---

## 13. Errores típicos

| Síntoma | Causa y solución |
|---|---|
| `remote: Repository not found` | Usuario o nombre del repo mal escrito, o el repo no existe. Copia la URL exacta de GitHub. |
| `Authentication failed` / pide contraseña | GitHub exige token (paso 5) o clave SSH. |
| `src refspec main does not match any` | No hay commits todavía: falta `git add . && git commit -m "..."`. |
| `failed to push some refs` / `non-fast-forward` | El repo remoto ya tiene archivos (README): `git pull --rebase origin main` y vuelve a subir. |
| `Updates were rejected because the remote contains work` | Igual que arriba: clonaste o creaste el repo con contenido. |
| `error: pathspec 'main' did not match` | Rama `master` antigua: ejecuta `git branch -M main` antes del push. |
| `file is 123.00 MB; this exceeds GitHub's file size limit` | Se coló un `build/` o un `.zip`: bórralo del índice con `git rm --cached -r build`. |
| El CI falla en `ios` con "No such module" | Falta `flutter pub get` en el job o el archivo no está en el target: revisa `scripts/ios_check.sh` en local. |
| El CI falla con `Podfile.lock` desactualizado | Ejecuta `cd ios && pod install` en local y sube el `Podfile.lock` actualizado. |
| Se subieron contraseñas | Cambia la contraseña, invalida el token y limpia el historial con `git filter-repo` (o borra el repo y vuelve a subirlo limpio). |

---

## 14. Ideas para la v2

* Exportar GPX/CSV del historial.
* Mapa offline con MBTiles (`flutter_map` + tiles locales).
* Racha y objetivos automáticos por semana.
* Integración con HealthKit / Health Connect.
* Notas de sesión y RPE para cruzar carga con velocidad.
