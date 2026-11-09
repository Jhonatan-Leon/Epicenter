# Epicenter

Sistema multiusuario en Elixir que simula una plataforma distribuida para coordinar y gestionar emergencias después de un terremoto.

Proyecto final de Programación III, Ingeniería de Sistemas y Computación, Universidad del Quindío (2026-2).

> **Estado:** base creada. Las funcionalidades todavía no están implementadas.

## Objetivo

Permitir que ciudadanos, voluntarios, coordinadores y administradores registren y consulten información de la emergencia al mismo tiempo, sin generar inconsistencias. Por ejemplo, dos solicitudes simultáneas nunca podrán asignar más unidades de un recurso que las disponibles en el inventario.

## Funcionalidades previstas

- **Usuarios:** conexión, registro automático, validación de credenciales, permisos por rol y registro de actividad.
- **Zonas:** zonas, sectores y puntos de atención, con nivel de afectación y estadísticas acumuladas.
- **Necesidades:** solicitudes de ayuda con tipo, cantidad, prioridad y estado.
- **Recursos:** inventario, entradas, salidas, asignaciones, transferencias e historial de movimientos.
- **Familiares:** búsqueda de personas, mensajes e historial de cambios de estado.
- **Mascotas:** reportes de animales perdidos o encontrados y búsqueda de coincidencias por similitud.
- **Albergues:** capacidad, ocupación, ingresos, salidas y reporte de mayor ocupación.
- **Persistencia:** almacenamiento de la información en archivos de texto plano.

## Conceptos aplicados

- Programación funcional: funciones puras, pattern matching, guards e inmutabilidad.
- Estructuras de datos: listas, mapas, tuplas, MapSet y estructuras anidadas.
- Recursividad sobre listas y estructuras jerárquicas.
- Concurrencia con procesos y paso de mensajes.
- Estado compartido con GenServer.
- Tolerancia a fallos con Supervisor y DynamicSupervisor.
- Pruebas automatizadas, incluidos conflictos concurrentes.

## Tecnologías

- Elixir 1.20.4
- Erlang/OTP 29
- Mix y ExUnit

## Ejecución

Compilar:

```bash
mix compile
```

Ejecutar las pruebas:

```bash
mix test
```

Abrir el sistema en una consola interactiva:

```bash
iex -S mix
```

## Estructura

- `lib/epicenter/application.ex`: árbol de procesos.
- `lib/epicenter/estructuras/`: estructuras compartidas.
- `lib/epicenter/`: módulos del sistema.
- `lib/epicenter/comandos/`
- `test/`: pruebas.
- `docs/decisiones.md`: reglas y responsables.
- `docs/comandos.md`: lista de comandos.

## Equipo

| Nombre completo | Código |
| --- | --- | 
| Ruben Steven Sanchez | 1092458430 | 
| Jhonatan Cardona Leon| 1092457799 | 
| Diana Gaona Valencia | 1092853450 | 

