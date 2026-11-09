Code.require_file("Utilidad.exs", __DIR__)
defmodule Epicenter.Necesidad do
  @moduledoc """
  """
  @enforce_keys [:id, :codigo_zona, :reportador_por]
  defstruct [:id, :codigo_zona, :reportador_por, :tipo, :descripicion, :cantidad, :prioridad, :estado, :destino]

  def nuevo(codigo_zona, reportador_por, tipo, descripicion, cantidad, prioridad, estado, destino) do
    {:Ok, %__MODULE__{id: Utilidad.generar_codigo_unico(), codigo_zona: Utilidad.verificar_zona(codigo_zona), reportador_por: reportador_por, tipo: tipo, descripicion: descripicion, cantidad: cantidad, prioridad: prioridad, estado: estado, destino: destino}}
  end

end
