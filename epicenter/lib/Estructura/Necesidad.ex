defmodule Epicenter.Necesidad do
  @moduledoc """
  """
  @tipos [
    :agua,
    :alimentos,
    :medicamentos,
    :primeros_auxilios,
    :refugio,
    :transporte,
    :rescate,
    :otra
  ]
  @prioridades [:critica, :alta, :media, :baja]
  @estados [:pendiente, :asignada, :en_atencion, :atendida, :cancelada]

  # Em este apartado se refiere a por ejemplo si una necesidad es atendida o cancelada entonces no cambiara
  @transiciones %{
    pendiente: [:asignada, :cancelada],
    asignada: [:en_atencion, :cancelada],
    en_atencion: [:atendida, :cancelada],
    atendida: [],
    cancelada: []
  }

  @enforce_keys [:id, :codigo_zona, :reportado_por, :tipo, :cantidad, :prioridad]
  defstruct [
    :id,
    :codigo_zona,
    :reportado_por,
    :tipo,
    :descripcion,
    :cantidad,
    :prioridad,
    :destino,
    estado: :pendiente,
    asignaciones: []
  ]

  def tipos, do: @tipos
  def prioridades, do: @prioridades
  def estados, do: @estados

  def nuevo(id, zona, por, tipo, descripcion, cantidad, prioridad, destino)
      when tipo in @tipos and prioridad in @prioridades and is_integer(cantidad) and cantidad > 0 do
    {:ok,
     %__MODULE__{
       id: id,
       codigo_zona: zona,
       reportado_por: por,
       tipo: tipo,
       descripcion: descripcion,
       cantidad: cantidad,
       prioridad: prioridad,
       destino: destino
     }}
  end

  # para que se entienda mas, se refiere a las iniciales de los atributos
  def nuevo(_id, _z, _p, tipo, _d, _c, _pr, _de) when tipo not in @tipos,
    do: {:error, :tipo_invalido}

  def nuevo(_id, _z, _p, _t, _d, _c, prioridad, _de) when prioridad not in @prioridades,
    do: {:error, :prioridad_invalida}

  def nuevo(_id, _z, _p, _t, _d, _c, _pr, _de), do: {:error, :cantidad_invalida}

  def cambiar_estado(%__MODULE__{} = necesidad, nuevo_estado) when nuevo_estado in @estados do
    estados_permitidos = Map.get(@transiciones, necesidad.estado)

    cond do
      cerrada?(necesidad) -> {:error, :ya_cerrada}
      nuevo_estado in estados_permitidos -> {:ok, %{necesidad | estado: nuevo_estado}}
      true -> {:error, :transicion_invalida}
    end
  end

  def cambiar_estado(_necesidad, _nuevo_estado), do: {:error, :estado_invalido}

  # Una necesidad atendida o cancelada ya esta cerrada
  def cerrada?(%__MODULE__{estado: estado}), do: estado in [:atendida, :cancelada]

  # Total de recursos que ya se le asignaron
  def cantidad_asignada(%__MODULE__{asignaciones: asignaciones}) do
    Enum.sum_by(asignaciones, fn asignacion -> asignacion.cantidad end)
  end

  # Lo que todavia le falta para cubrir lo que se pidio
  def cantidad_faltante(%__MODULE__{} = necesidad) do
    necesidad.cantidad - cantidad_asignada(necesidad)
  end

  def asignar_recurso(%__MODULE__{} = necesidad, codigo_recurso, cantidad)
      when is_integer(cantidad) and cantidad > 0 do
    cond do
      cerrada?(necesidad) ->
        {:error, :ya_cerrada}

      cantidad > cantidad_faltante(necesidad) ->
        {:error, :supera_lo_requerido}

      true ->
        nueva_asignacion = %{recurso: codigo_recurso, cantidad: cantidad}
        asignaciones = necesidad.asignaciones ++ [nueva_asignacion]
        {:ok, %{necesidad | asignaciones: asignaciones, estado: :asignada}}
    end
  end

  def asignar_recurso(_necesidad, _codigo_recurso, _cantidad), do: {:error, :cantidad_invalida}
  
end
