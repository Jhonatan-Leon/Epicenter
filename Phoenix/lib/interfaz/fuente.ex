defmodule Interfaz.Fuente do
  @moduledoc """
  Puente entre la interfaz y la lógica (`epicenter/`). Está partido en un
  módulo por gestión, para que cada archivo sea corto y fácil de leer:

    * `Interfaz.Fuente.Sesion`      conectar y registrar usuarios
    * `Interfaz.Fuente.Zonas`       zonas, sectores y puntos de atención
    * `Interfaz.Fuente.Necesidades` necesidades y asignación de recursos
    * `Interfaz.Fuente.Recursos`    inventario, movimientos y transferencias
    * `Interfaz.Fuente.Personas`    personas reportadas
    * `Interfaz.Fuente.Mensajes`    mensajes familiares
    * `Interfaz.Fuente.Mascotas`    mascotas y coincidencias
    * `Interfaz.Fuente.Albergues`   albergues, ingresos y salidas
    * `Interfaz.Fuente.Resumen`     cifras que juntan varias gestiones
    * `Interfaz.Fuente.Actividad`   usuarios conectados y registro de actividad
    * `Interfaz.Fuente.Catalogos`   valores para los `<select>`
    * `Interfaz.Fuente.Comun`       validaciones, fechas y mensajes de error

  Reglas que siguen todos:

    1. Hablan con la lógica solo por sus GenServers (`Epicenter.Genserver*`),
       que atienden una operación a la vez.
    2. Toda operación que cambia datos pasa por `Comun.con_permiso/4`, que
       revisa el rol y la zona en la lógica (`Epicenter.Autorizacion`).
    3. Devuelven mapas simples para las vistas y `{:ok, mensaje}` o
       `{:error, mensaje}` ya en español.
  """
end
