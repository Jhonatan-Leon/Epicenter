defmodule Epicenter.PuntoAtencion do
  @enforce_keys [:codigo, :nombre]
  defstruct [:codigo, :nombre]

  def nuevo(_codigo, ""), do: {:error, :nombre_vacio}
  def nuevo(codigo, nombre), do: {:ok, %__MODULE__{codigo: codigo, nombre: nombre}}
end
