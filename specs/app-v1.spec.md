# Especificación App V1 - Adondeamos

## 1. Objetivo

Convertir la app Flutter actual en un cliente V1 completo del backend ya construido. La V1 debe permitir que una persona o grupo guarde lugares vistos en redes, organice pendientes y decida a dónde ir sin depender de datos de muestra.

La prioridad no es agregar IA todavía. La prioridad es cerrar el ciclo real:

Registro -> login -> buscar/guardar lugar -> organizar -> invitar -> aceptar -> decidir -> votar -> match -> visitar.

## 2. Usuarios Principales

- Usuario individual: guarda lugares para después y decide rápido cuando quiere salir.
- Pareja o grupo pequeño: comparte lugares, vota opciones y encuentra coincidencias.
- Usuario explorador: busca lugares cercanos o por nombre y los guarda desde la app.

## 3. Alcance V1

Incluido:

- Autenticación.
- Captura y guardado de lugares.
- Búsqueda de lugares con Google Places a través del backend.
- Mis lugares pendientes y visitados.
- Grupos e invitaciones confirmadas.
- Listas personales y grupales.
- Decisiones con opciones, votos y match.
- Estados de carga, vacío y error.
- Smoke test manual documentado.

No incluido en V1:

- IA/recomendador personalizado.
- Feed social público.
- Fotos/reseñas propias.
- Ranking, follows, badges públicos.
- Push notifications.
- Compartir nativo desde otras apps hacia Adondeamos.
- Pagos, monetización o panel admin.

## 4. Requisitos Funcionales EARS

### Auth

- When el usuario abre la app sin token guardado, the app shall mostrar la pantalla de login/registro.
- When el usuario registra nombre, correo y contraseña válidos, the app shall crear la cuenta vía `/auth/register` y entrar al shell principal.
- When el usuario inicia sesión con credenciales válidas, the app shall guardar el token localmente y cargar `/me`.
- When el token guardado ya no es válido, the app shall limpiar la sesión y volver al login.
- When el usuario toca "Cerrar sesión", the app shall borrar el token y volver al login.

### Lugares Y Guardados

- When el usuario busca un lugar por texto, the app shall consultar `/places/search?q=...`.
- When el usuario selecciona una predicción de Google, the app shall resolverla con `/places/resolve`.
- When el usuario guarda un lugar resuelto, the app shall crear el guardado con `/saves`.
- When el usuario pega un enlace de red social, the app shall detectar `sourceNetwork` y permitir asociarlo al guardado.
- When el usuario guarda un lugar propio/manual, the app shall usar `/places` y luego `/saves`.
- When el usuario abre "Mis lugares", the app shall cargar `/saves?status=pending`.
- When el usuario filtra visitados, the app shall cargar `/saves?status=visited`.
- When el usuario marca un guardado como visitado, the app shall llamar `PATCH /saves/{id}` con `visited=true`.
- When el usuario elimina un guardado, the app shall llamar `DELETE /saves/{id}` y actualizar la lista.

### Home Y Explorar

- Where Home is active, the app shall mostrar resumen real de pendientes, actividad reciente y recomendación simple derivada de guardados.
- Where Explorar is active, the app shall permitir buscar lugares y guardar resultados reales.
- Where no hay datos suficientes, the app shall mostrar estados vacíos accionables, no contenido falso como si fuera real.

### Grupos E Invitaciones

- When el usuario crea un grupo, the app shall llamar `POST /groups`.
- When el usuario ve sus grupos, the app shall llamar `GET /groups`.
- When el usuario invita por correo, the app shall llamar `POST /groups/{id}/invitations`.
- When el usuario ve invitaciones pendientes, the app shall llamar `GET /me/invitations`.
- When el usuario acepta una invitación, the app shall llamar `POST /invitations/{id}/accept` y mostrar el grupo en su lista.
- When el usuario rechaza una invitación, the app shall llamar `POST /invitations/{id}/reject` y quitarla de pendientes.

### Listas

- When el usuario crea una lista personal, the app shall llamar `POST /lists` sin `groupId`.
- When el usuario crea una lista grupal, the app shall llamar `POST /lists` con `groupId` y `visibility=group`.
- When el usuario agrega un guardado a una lista, the app shall llamar `POST /lists/{id}/items`.
- When el usuario quita un guardado de una lista, the app shall llamar `DELETE /lists/{id}/items/{saveId}`.
- When el usuario abre una lista, the app shall mostrar detalle desde `GET /lists/{id}`.

### Decidir Y Match

- When el usuario inicia una decisión individual, the app shall llamar `POST /decisions` sin grupo.
- When el usuario inicia una decisión grupal, the app shall llamar `POST /decisions` con `groupId`.
- When el usuario agrega opciones manuales, the app shall llamar `POST /decisions/{id}/options` con `placeIds`.
- When el usuario quiere llenar opciones desde pendientes, the app shall llamar `POST /decisions/{id}/options` con `autoFillFromSaves=true`.
- When el usuario vota una opción, the app shall llamar `POST /decisions/{id}/options/{optionId}/votes` con `isYes=true|false`.
- When todos los participantes necesarios coinciden en una opción, the app shall mostrar el match persistido desde `GET /decisions/{id}`.

## 5. Requisitos No Funcionales

- La app debe responder a interacciones principales en menos de 2 segundos cuando el API responde normalmente.
- Toda pantalla con llamada remota debe tener loading, error y empty state.
- El token debe almacenarse con el mecanismo local disponible en Flutter V1; para producción se evaluará storage seguro.
- La app no debe mostrar datos sample mezclados con datos reales sin indicarlo.
- Los errores del API deben mostrarse en español y sin stack traces.
- La app debe pasar `flutter analyze` sin issues.
- La app debe tener pruebas mínimas de auth, guardados y flujo de decisión.
- El backend no debe persistir datos restringidos de Google Places fuera de `google_place_id`, respetando la regla ya definida.

## 6. Criterios De Aceptación

### Registro Y Sesión

Given un usuario nuevo está en la pantalla de registro,
When captura nombre, correo y contraseña válidos,
Then entra a Inicio y puede ver su nombre en la app.

Given un usuario con sesión guardada,
When abre la app,
Then entra directamente al shell principal sin volver a login.

### Guardar Lugar

Given el usuario está autenticado,
When busca "tacos nuevo laredo", selecciona un resultado y toca guardar,
Then el lugar aparece en "Mis lugares" como pendiente.

Given el usuario tiene un guardado pendiente,
When lo marca como visitado,
Then desaparece de pendientes y aparece en visitados.

### Invitaciones

Given Eduardo creó un grupo,
When invita a otro usuario por correo,
Then el invitado ve la invitación en pendientes.

Given el invitado ve una invitación,
When acepta,
Then aparece como miembro del grupo y puede ver el detalle.

### Listas

Given el usuario tiene guardados pendientes,
When crea una lista "Sábado en la noche" y agrega dos lugares,
Then el detalle de la lista muestra ambos lugares en orden.

### Decisión

Given dos miembros pertenecen al mismo grupo y tienen opciones disponibles,
When ambos votan sí por la misma opción,
Then la app muestra pantalla de match con el lugar coincidente.

## 7. Manejo De Errores

| Caso | Respuesta esperada |
|---|---|
| API apagado | Mostrar "No pude conectar con el API" y permitir reintentar |
| Token expirado | Cerrar sesión local y volver a login |
| Email ya registrado | Mostrar mensaje del API en registro |
| Sin resultados de búsqueda | Mostrar estado vacío con opción de crear lugar manual |
| Invitación duplicada | Mostrar mensaje claro y no duplicar UI |
| Guardado duplicado | Mostrar que el lugar ya está guardado |
| Sin conexión | Mostrar error persistente y no perder formulario |
| Voto duplicado o cambiado | Reflejar el estado final devuelto por el API |

## 8. Plan De Implementación

### Sprint 0 - Base De Proyecto

- Inicializar git en la app Flutter.
- Hacer commit del estado actual.
- Separar `ApiClient` en clientes por dominio.
- Crear modelos faltantes: groups, invitations, lists, decisions.
- Definir rutas/navegación estable.
- Agregar carpeta `features` consistente por dominio.

### Sprint 1 - Guardados Reales

- Integrar búsqueda `/places/search`.
- Integrar resolución `/places/resolve`.
- Rediseñar `CaptureScreen` para búsqueda + enlace + guardado manual.
- Implementar pending/visited en `SavesScreen`.
- Implementar marcar visitado y borrar.
- Reemplazar datos sample de Home cuando haya guardados reales.

### Sprint 2 - Grupos

- Pantalla de grupos.
- Crear grupo.
- Ver detalle y miembros.
- Invitar por correo.
- Pantalla de invitaciones pendientes.
- Aceptar/rechazar.

### Sprint 3 - Listas

- Crear lista personal/grupal.
- Agregar guardados a lista.
- Ver detalle de lista.
- Quitar elementos.
- Pantalla "Plan" inspirada en el mockup.

### Sprint 4 - Decidir

- Crear sesión individual/grupal.
- Seleccionar opciones desde guardados/listas.
- Pantalla de voto.
- Pantalla de match.
- Refrescar estado de decisión.

### Sprint 5 - Cierre V1

- Pruebas widget/unitarias principales.
- Smoke manual documentado.
- README actualizado.
- Revisión visual en web y mobile.
- Commit estable.

## 9. Smoke Test Humano V1

1. Registrar usuario A.
2. Registrar usuario B.
3. Usuario A busca y guarda un lugar.
4. Usuario A crea un grupo.
5. Usuario A invita a usuario B.
6. Usuario B acepta.
7. Usuario A crea una lista grupal.
8. Usuario A agrega el lugar a la lista.
9. Usuario A crea una decisión grupal.
10. Usuario A agrega opciones por `placeIds` o `autoFillFromSaves=true`.
11. Usuario A y B votan sí por el mismo lugar.
12. La app muestra match.
13. Usuario A marca el guardado como visitado.

## 10. Definición De Terminado

La App V1 se considera terminada cuando:

- El smoke test humano completo pasa contra el backend local.
- `flutter analyze` no reporta issues.
- `flutter test` pasa.
- No quedan pantallas principales usando datos sample como si fueran reales.
- La app tiene README actualizado.
- El estado queda commiteado.
