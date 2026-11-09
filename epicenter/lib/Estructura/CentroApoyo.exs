defmodule Epicenter.CentroApoyo do
  @moduledoc """
  """
  @enforce_keys [:nombre, :tipo]
  defstruct [:codigo, :nombre, :tipo, :codigo_zona]

  def nuevo(nombre, tipo, codigo_zona) do
    {:Ok, %__MODULE__{codigo: generar_id(), nombre: nombre, tipo: tipo, codigo_zona: codigo_zona}}
  end

  defp generar_id do
    numero = Enum.random(100..999)
    letra = Enum.random(?A..?Z)
    "#{numero}#{<<letra::utf8>>}"
  end

end
