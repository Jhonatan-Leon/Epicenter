defmodule Interfaz.Fuente.Necesidades do
  @moduledoc """
  Necesidades de la emergencia, por `Epicenter.GenserverNecesidad`.

  Asignar un recurso pasa por `Epicenter.GenserverRecurso`: descuenta el
  inventario y anota la asignación en la necesidad en una sola operación,
  así dos asignaciones al mismo tiempo no gastan más de lo que hay.
  """

  import Interfaz.Fuente.Comun

  alias Epicenter.{GenserverNecesidad, GenserverRecurso, Necesidad}

  @doc """
  Comando `list_needs`: ya vienen ordenadas por prioridad (crítica primero).
  Los filtros llegan del formulario: zona, tipo, prioridad y estado; los vacíos se ignoran.
  """
  def necesidades(filtros \\ %{}) do
    filtros = %{
      zona: Map.get(filtros, "zona", ""),
      tipo: Map.get(filtros, "tipo", ""),
      prioridad: Map.get(filtros, "prioridad", ""),
      estado: Map.get(filtros, "estado", "")
    }

    filtros |> GenserverNecesidad.consultar() |> lista(&a_mapa/1)
  end

  @doc "Comando `pending_needs`: las abiertas, de mayor a menor prioridad."
  def pendientes, do: GenserverNecesidad.pendientes() |> lista(&a_mapa/1)

  @doc "Una necesidad por su id (`nil` si no existe)."
  def obtener(id), do: Enum.find(necesidades(), &(&1.id == id))

  @doc """
  Comando `register_need`. Solo coordinación y administración pueden
  registrar necesidades críticas.
  """
  def registrar(datos, usuario) do
    permiso =
      if datos["prioridad"] == "critica",
        do: :registrar_necesidad_critica,
        else: :registrar_necesidad

    with {:ok, descripcion} <- texto(datos["descripcion"], "Escribe una descripción."),
         {:ok, zona} <- texto(datos["zona"], "Elige una zona.") do
      con_permiso(usuario, permiso, zona, fn actor ->
        zona
        |> GenserverNecesidad.registrar(
          actor.nombre_usuario,
          datos["tipo"],
          descripcion,
          datos["cantidad"],
          datos["prioridad"]
        )
        |> responder(&"Necesidad #{&1.id} registrada.")
      end)
    end
  end

  @doc "Comando `update_need`: cambia el estado si la transición está permitida."
  def cambiar_estado(id, estado, usuario) do
    con_necesidad(id, fn necesidad ->
      con_permiso(usuario, :cambiar_estado_necesidad, necesidad.zona, fn _actor ->
        id
        |> GenserverNecesidad.cambiar_estado(estado)
        |> responder(&"Necesidad #{&1.id} ahora está #{InterfazWeb.Formato.t(&1.estado)}.")
      end)
    end)
  end

  @doc "Comando `assign_resource`: descuenta el inventario y anota la asignación."
  def asignar_recurso(id, codigo_recurso, cantidad, usuario) do
    con_necesidad(id, fn necesidad ->
      con_permiso(usuario, :asignar_recurso, necesidad.zona, fn actor ->
        codigo_recurso
        |> GenserverRecurso.asignar_a_necesidad(id, cantidad, actor.nombre_usuario)
        |> responder(
          &"Asignado a #{id}. #{&1.nombre} queda en #{&1.cantidad_disponible} #{&1.unidad_medida}."
        )
      end)
    end)
  end

  defp con_necesidad(id, funcion) do
    case obtener(id) do
      nil -> {:error, traducir(:necesidad_no_encontrada)}
      necesidad -> funcion.(necesidad)
    end
  end

  defp a_mapa(%Necesidad{} = necesidad) do
    %{
      id: necesidad.id,
      tipo: necesidad.tipo,
      descripcion: necesidad.descripcion,
      cantidad: necesidad.cantidad,
      asignada: Necesidad.cantidad_asignada(necesidad),
      faltante: Necesidad.cantidad_faltante(necesidad),
      prioridad: necesidad.prioridad,
      estado: necesidad.estado,
      zona: necesidad.codigo_zona,
      responsable: necesidad.reportado_por,
      cerrada: Necesidad.cerrada?(necesidad)
    }
  end
end
