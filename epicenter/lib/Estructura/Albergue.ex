defmodule Epicenter.Albergue do
  @moduledoc """
  """
  @enforce_keys [:codigo, :nombre, :codigo_zona, :capacidad]
  defstruct [:codigo, :nombre, :codigo_zona, :capacidad, :ocupantes, :recursos, :necesidades ]

  def nuevo(nombre, codigo_zona, capacidad) do
    {:ok, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), nombre: nombre, codigo_zona: codigo_zona, capacidad: capacidad, ocupantes: 0, recursos: [], necesidades: []}}
  end


  def maxima_capacidad(%__MODULE__{capacidad: capacidad}) do
    capacidad
  end

  def ocupacion_actual(%__MODULE__{ocupantes: ocupantes}) do
    ocupantes
  end

  def ocupacion_disponible?(%__MODULE__{capacidad: capacidad, ocupantes: ocupantes}) do
    ocupantes < capacidad
  end
end
