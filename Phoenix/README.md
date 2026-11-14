# Epicenter · Interfaz gráfica (Phoenix)

Interfaz web del sistema de coordinación de emergencias, hecha con Phoenix 1.8 y LiveView.
Esta carpeta contiene **solo la interfaz**: no implementa reglas de negocio. La lógica del
sistema vive en `../epicenter`.

## Ejecutar

```bash
cd Phoenix
mix setup
mix phx.server
```

Abrir <http://localhost:4000>. Para conectarse basta con cualquier usuario y contraseña
(mientras no esté conectada la lógica), eligiendo el tipo de usuario y la zona.

Pruebas de la interfaz:

```bash
mix test
```

## Pantallas

| Ruta | Pantalla | Comandos del enunciado que cubre |
| --- | --- | --- |
| `/conectar` | Conexión | `connect`, `disconnect` |
| `/` | Resumen | `summary`, `pending_needs`, `critical_resources` |
| `/zonas` | Zonas → sectores → puntos de atención | `register_zone`, estadísticas por zona |
| `/necesidades` | Necesidades con filtros y orden por prioridad | `register_need`, `list_needs`, `assign_resource` |
| `/recursos` | Inventario, movimientos y transferencias | `register_resource`, `list_resources`, `transfer_resource` |
| `/personas` | Personas, historial de estado y mensajes | `report_person`, `find_person`, `send_family_message`, `list_family_messages` |
| `/mascotas` | Reportes y posibles coincidencias | `report_pet`, `match_pets` |
| `/albergues` | Cupos, ingresos/salidas y ranking de ocupación | `register_shelter`, `check_shelter`, `register_entry`, `register_exit` |
| `/actividad` | Usuarios conectados y registro de actividad | — |

El menú muestra solo las secciones permitidas para el rol (por ejemplo, un ciudadano no ve
Recursos ni Actividad). La restricción real de operaciones corresponde a la lógica.

## Cómo conectar la lógica

Todo el intercambio de datos pasa por un único módulo: `lib/interfaz/fuente.ex`.

- Las funciones de consulta (`zonas/0`, `necesidades/0`, `recursos/0`, `resumen/0`, …)
  devuelven hoy datos de muestra basados en el flujo de ejemplo del enunciado.
- `conectar/4` recibe las credenciales del formulario de conexión.
- `ejecutar/2` recibe cada acción de los formularios (`"register_need"`, `"assign_resource"`,
  …) con sus argumentos en el orden de los comandos del enunciado. Hoy solo devuelve el
  comando equivalente, que la interfaz muestra como confirmación.

Para integrar basta con reemplazar el cuerpo de esas funciones por llamadas a los
GenServers/módulos de `epicenter` y devolver `{:ok, mensaje}` o `{:error, motivo}`; las
vistas no necesitan cambios.

## Estructura

```
lib/
  interfaz/fuente.ex              punto de conexión con la lógica (datos de muestra)
  interfaz_web/
    sesion.ex                     menú por rol y protección de vistas
    components/ui.ex              insignias, indicadores, barras, paneles, modales
    components/layouts.ex         estructura general (menú lateral y barra superior)
    controllers/sesion_*          pantalla de conexión
    live/*_live.ex                una vista LiveView por sección
```
