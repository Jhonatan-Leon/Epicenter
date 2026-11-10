defmodule Epicenter.Sector do
  @moduledoc """
  """
  @nivel_afectacion_verificar [:bajo, :medio, :alto]
  @enforce_keys [:codigo_zona, :nombre]
  defstruct [:codigo_zona, :nombre, :nivel_afectacion, personas_afectadas: 0]

  def nuevo(codigo_zona, nombre) do
    {:ok, %__MODULE__{codigo_zona: codigo_zona, nombre: nombre}}
  end
end
