defmodule Epicenter.Zona do
  @moduledoc """

  """
  @nivel_afectacion_verificar [:bajo, :medio, :alto]
  @enforces_keys [:nombre_zona]
  defstruct [ :codigo, :nombre_zona, :nivel_afectacion, persona_afectadas: 0, sectores: []]

  def nueva(nombre_zona) do
    {:Ok, %__MODULE__{nombre_zona: nombre_zona}}
  end
end
