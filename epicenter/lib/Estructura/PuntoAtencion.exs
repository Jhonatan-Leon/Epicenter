defmodule Epicenter.PuntoAtencion do
  @moduledoc """
  """
  @enforce_keys [:codigo, :codigo_sector]
  defstruct [:codigo, :codigo_sector, :nombre]

  def nuevo(codigo, nombre, direccion, telefono) do
    {:Ok, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), codigo_sector: codigo_sector,  nombre: nombre}}
  end
end
