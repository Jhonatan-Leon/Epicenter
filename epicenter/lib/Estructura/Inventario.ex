defmodule Epicenter.Inventario do
  @moduledoc """
  """
  @enforce_keys [:id, :codigo_recurso, :codigo_centro]
  defstruct [:id, :zonas, :codigo_recurso, :codigo_centro, cantidad_disponible: 0]

  def nuevo(codigo_recurso, codigo_centro) do
    {:ok,
     %__MODULE__{
       id: Utilidad.generar_codigo_unico(),
       codigo_recurso: codigo_recurso,
       codigo_centro: codigo_centro
     }}
  end

  def nuevo(codigo_recurso, codigo_centro, zonas, cantidad_disponible) do
    with {:ok, inventario} <- nuevo(codigo_recurso, codigo_centro) do
      completar_inventario(inventario, zonas, cantidad_disponible)
    end
  end

  def completar_inventario(%__MODULE__{} = inventario, zonas, cantidad_disponible) do
    {:ok, %__MODULE__{inventario | zonas: zonas, cantidad_disponible: cantidad_disponible}}
  end
end
