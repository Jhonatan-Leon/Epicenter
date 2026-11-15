defmodule Interfaz.Fuente.Actividad do
  @moduledoc """
  Usuarios y registro de actividad, por `Epicenter.Genserver` (usuarios) y
  `Epicenter.GenserverActividad` (Actividad.log).

  La lógica guarda en Actividad.log cada conexión, desconexión y operación
  (también las rechazadas por permisos). Un usuario está conectado si su
  último registro de conexión es un `connect`.
  """

  import Interfaz.Fuente.Comun, only: [fecha_corta: 1]

  alias Epicenter.{Genserver, GenserverActividad}

  @doc "Usuarios registrados, con su estado de conexión. Primero los conectados."
  def usuarios do
    conectados =
      case GenserverActividad.conectados() do
        {:ok, nombres} -> MapSet.new(nombres)
        {:error, _motivo} -> MapSet.new()
      end

    case Genserver.listar() do
      {:ok, usuarios} ->
        usuarios
        |> Enum.map(fn usuario ->
          %{
            usuario: usuario.nombre_usuario,
            nombre: usuario.nombre_completo || usuario.nombre_usuario,
            rol: rol_interfaz(usuario.rol),
            zona: usuario.zona_principal,
            conectado: MapSet.member?(conectados, usuario.nombre_usuario)
          }
        end)
        |> Enum.sort_by(&{not &1.conectado, &1.nombre})

      {:error, _motivo} ->
        []
    end
  end

  @doc "Registro de actividad, del más reciente al más antiguo (todos o de un usuario)."
  def actividad(usuario \\ "")

  def actividad(""), do: GenserverActividad.listar() |> a_mapas()
  def actividad(usuario), do: GenserverActividad.de_usuario(usuario) |> a_mapas()

  defp a_mapas({:ok, actividades}) do
    Enum.map(actividades, fn actividad ->
      %{
        fecha: fecha_corta(actividad.fecha),
        usuario: actividad.usuario,
        accion: texto_accion(actividad.accion),
        resultado: if(actividad.resultado == "ok", do: :ok, else: :error),
        detalle: if(actividad.detalle in [nil, ""], do: nil, else: actividad.detalle)
      }
    end)
  end

  defp a_mapas({:error, _motivo}), do: []

  # La lógica guarda el nombre del permiso; en pantalla se muestra en español.
  @acciones %{
    "connect" => "Se conectó",
    "disconnect" => "Se desconectó",
    "registrar_necesidad" => "Registró una necesidad",
    "registrar_necesidad_critica" => "Registró una necesidad crítica",
    "cambiar_estado_necesidad" => "Cambió el estado de una necesidad",
    "asignar_recurso" => "Asignó un recurso",
    "gestionar_recursos" => "Movió inventario",
    "transferir_recursos" => "Transfirió recursos",
    "administrar_configuracion" => "Registró una zona",
    "registrar_sector" => "Registró un sector",
    "registrar_punto_atencion" => "Registró un punto de atención",
    "registrar_albergue" => "Registró un albergue",
    "registrar_ingreso_albergue" => "Registró un ingreso a albergue",
    "registrar_salida_albergue" => "Registró una salida de albergue",
    "registrar_persona" => "Reportó una persona",
    "actualizar_persona" => "Cambió el estado de una persona",
    "enviar_mensaje" => "Envió un mensaje familiar",
    "marcar_mensaje" => "Marcó un mensaje",
    "reportar_mascota" => "Reportó una mascota",
    "validar_coincidencias_mascotas" => "Revisó coincidencias de mascotas"
  }

  defp texto_accion(accion), do: Map.get(@acciones, accion, accion)

  defp rol_interfaz(:coordinar), do: :coordinador
  defp rol_interfaz(rol) when rol in [:ciudadano, :voluntario, :administrador], do: rol
  defp rol_interfaz(_rol), do: :ciudadano
end
