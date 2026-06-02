# Adondeamos — Build & Deploy

## 1️⃣ APK (Android)

### Requisitos previos
- Flutter SDK 3.x+
- Java 17 (JDK)
- Android SDK configurado

### Generar keystore (una sola vez)

```bash
cd C:\Codigos\adondeamos-app\adondeamos

keytool -genkey -v `
  -keystore android/app/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload `
  -storetype JKS
```

Te pedirá contraseñas y datos. Guarda las contraseñas en un lugar seguro.

### Configurar key.properties

Edita `android/key.properties` con las contraseñas reales:

```properties
storePassword=TU_CONTRASENA_DEL_KEYSTORE
keyPassword=TU_CONTRASENA_DE_LA_LLAVE
keyAlias=upload
storeFile=upload-keystore.jks
```

### Construir APK release

```bash
flutter build apk --release
```

El APK se genera en: `build/app/outputs/flutter-apk/app-release.apk`

### Opciones adicionales

```bash
# APK por arquitectura (más chico, recomendado para Play Store)
flutter build apk --release --split-per-abi

# App Bundle (requerido por Google Play desde 2021)
flutter build appbundle --release
```

### Antes de publicar en Play Console

- [ ] Cambiar el ícono de la app (`android/app/src/main/res/mipmap-*/ic_launcher.png`)
- [ ] Verificar que `applicationId = "com.adondeamos.app"` sea el definitivo
- [ ] Subir el App Bundle (`.aab`), no el APK
- [ ] Completar la ficha de Play Store (descripción, screenshots, política de privacidad)

---

## 2️⃣ API (Render)

### Deploy con render.yaml (Infraestructura como Código)

```bash
cd C:\Codigos\adondeamos-api

# Push a GitHub (el repo debe estar conectado a Render)
git add Dockerfile .dockerignore render.yaml
git commit -m "Prepara deploy a Render con Docker + config"
git push
```

### Configurar secretos en Render

Después del primer deploy, ve a la UI de Render → tu Web Service → Environment y configura estos secretos:

| Variable | Ejemplo |
|----------|---------|
| `ConnectionStrings__Default` | `Host=ep-xxx.neon.tech;Database=adondeamos;Username=...;Password=...;SSL Mode=Require;Trust Server Certificate=true` |
| `Jwt__Secret` | Clave aleatoria de 32+ caracteres |
| `GooglePlaces__ApiKey` | `AIzaSy...` |
| `Email__Smtp__Password` | Contraseña SMTP |

### Verificar

```bash
# Health check
curl https://adondeamos-api.onrender.com/health
# → "Healthy"

# Swagger (solo si lo habilitas en prod)
curl https://adondeamos-api.onrender.com/swagger/index.html
```

---

## 3️⃣ Variables de entorno en Flutter para prod

Al compilar el APK para producción, define la URL de la API:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://adondeamos-api.onrender.com
```

O mejor, configura `lib/app/app_config.dart` para que use automáticamente la URL de producción cuando compile en modo release.
