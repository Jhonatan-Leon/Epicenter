defmodule Epicenter.Albergue do
  @moduledoc """
  """
  @enforce_keys [:codigo, :nombre, :codigo_zona, :capacidad]
  defstruct [
    :codigo,
    :nombre,
    :codigo_zona,
    :capacidad,
    ocupantes: [],
    recursos: [],
    necesidades: []
  ]

  def nuevo(_codigo, "", _zona, _capacidad), do: {:error, :nombre_vacio}
  def nuevo(_codigo, _nombre, "", _capacidad), do: {:error, :zona_vacia}

  def nuevo(codigo, nombre, codigo_zona, capacidad) when is_integer(capacidad) and capacidad > 0,
    do:
      {:ok,
       %__MODULE__{codigo: codigo, nombre: nombre, codigo_zona: codigo_zona, capacidad: capacidad}}

  def nuevo(_codigo, _nombre, _zona, _capacidad), do: {:error, :capacidad_invalida}

  def completar_albergue(%__MODULE__{} = albergue, ocupantes, recursos, necesidades) do
    {:ok,
     %__MODULE__{
       albergue
       | ocupantes: ocupantes,
         recursos: recursos,
         necesidades: necesidades
     }}
  end

  def ocupacion(%__MODULE__{ocupantes: ocupantes}), do: length(ocupantes)
  def cupos(%__MODULE__{capacidad: capacidad} = a), do: capacidad - ocupacion(a)
  def porcentaje(%__MODULE__{capacidad: capacidad} = a), do: div(ocupacion(a) * 100, capacidad)

  # Ingreso: no se repite la persona y no se supera la capacidad.
  def registrar_ingreso(%__MODULE__{} = a, documento) do
    cond do
      documento in a.ocupantes -> {:error, :ya_esta_en_el_albergue}
      cupos(a) <= 0 -> {:error, :sin_cupo}
      true -> {:ok, %{a | ocupantes: a.ocupantes ++ [documento]}}
    end
  end

  def registrar_salida(%__MODULE__{} = a, documento) do
    if documento in a.ocupantes,
      do: {:ok, %{a | ocupantes: List.delete(a.ocupantes, documento)}},
      else: {:error, :no_esta_en_el_albergue}
  end

  # Asociar por código, sin repetir.
  def asociar_recurso(%__MODULE__{} = a, codigo),
    do: {:ok, %{a | recursos: agregar_unico(a.recursos, codigo)}}

  def asociar_necesidad(%__MODULE__{} = a, id),
    do: {:ok, %{a | necesidades: agregar_unico(a.necesidades, id)}}

  defp agregar_unico(lista, valor), do: if(valor in lista, do: lista, else: lista ++ [valor])
end
