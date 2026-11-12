defmodule Epicenter.Recurso do
  @moduledoc """
  """
  @enforce_keys [:codigo, :nombre, :categoria]
  defstruct [:codigo, :nombre, :categoria, :unidad_medida, cantidad_disponible: 0]

  def nuevo(nombre, categoria) do
    {:ok,%__MODULE__{codigo: Utilidad.generar_codigo_unico(), nombre: nombre,categoria: categoria}}
  end

  def nuevo(nombre, categoria, cantidad_disponible, unidad_medida) do
    with {:ok, recurso} <- nuevo(nombre, categoria) do
      completar_recurso(recurso, cantidad_disponible, unidad_medida)
    end
  end

  def completar_recurso(%__MODULE__{} = recurso, cantidad_disponible, unidad_medida) do
    {:ok, %__MODULE__{recurso| unidad_medida: unidad_medida, cantidad_disponible: cantidad_disponible}}
  end

  def actualizar_cantidad_disponible(recurso, cantidad) do
    {:ok, %__MODULE__{recurso | cantidad_disponible: cantidad}}
  end

  def verificar_cantidad(cantidad) when cantidad > 0 do
    cantidad
  end
end
