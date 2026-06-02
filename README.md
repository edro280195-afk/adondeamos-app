# Adondeamos App V1

App Flutter oficial para consumir el backend V1 de Adondeamos. 

## Estado Actual (V1 Completada)

La aplicación implementa la arquitectura completa V1 orientada a dominios usando **Riverpod 3**.

**Funciones implementadas:**
- **Autenticación**: Registro y login con persistencia de sesión (`SharedPreferences`).
- **Lugares y Guardados (Saves)**: Captura manual y búsqueda de lugares con Google Places. Lista separada por estado (Pendientes / Visitados) con soporte para eliminar o marcar como visitados.
- **Grupos e Invitaciones**: Creación de grupos, envío de invitaciones por email, visualización de invitaciones pendientes con acciones de aceptar o rechazar.
- **Listas**: Listas de lugares personales o grupales, con reordenamiento y swipe para eliminar.
- **Decisiones (Voting System)**: Sesiones de votación de lugares en grupo o individual. Soporte para rellenado automático desde lugares guardados, sistema de *swipes/votos* (Sí/No) y vista dinámica de "¡Match!" cuando todos los usuarios aprueban un lugar.

## Arquitectura

- **Estado**: `flutter_riverpod` (v3). Uso de `AsyncNotifier` y `.family` para estados asíncronos y vinculados a parámetros (como los detalles por ID).
- **Red**: Múltiples clientes de API separados por dominio (`AuthApi`, `SavesApi`, `GroupsApi`, `ListsApi`, etc.) que utilizan un cliente HTTP unificado (`HttpApiClient`) con manejo de excepciones `ApiException`.

## Ejecutar

Asegúrate de levantar el backend API en `C:\Codigos\adondeamos-api` antes de iniciar la app.

Web o Windows local:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5172
```

Android Emulator:

```powershell
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:5172
```

Teléfono físico en la misma red:

```powershell
flutter run --dart-define=API_BASE_URL=http://IP-DE-TU-PC:5172
```

## Pruebas y Validación

```powershell
flutter analyze
flutter test
```
