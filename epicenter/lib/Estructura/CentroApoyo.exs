defmodule Epicenter.CentroApoyo do
  @moduledoc """
  """
  @enforce_keys [:nombre, :tipo]
  defstruct [:codigo, :nombre, :tipo, :codigo_zona]

  def nuevo(nombre, tipo, codigo_zona) do
    {:Ok, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), nombre: nombre, tipo: tipo, codigo_zona: codigo_zona}}
  end

end
