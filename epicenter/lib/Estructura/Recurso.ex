defmodule Epicenter.Recurso do
  @moduledoc """
  """
  defstruct [:codigo, :nombre, :categoria, :unidad_medida, cantidad_disponible: 0]

  def nuevo(codigo, nombre, categoria, unidad_medida, cantidad_disponible) do
    {:ok, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), nombre: nombre, categoria: categoria, unidad_medida: unidad_medida, cantidad_disponible: cantidad_disponible}}
  end

  def actualizar_cantidad_disponible(recurso, cantidad) do
    {:ok, %__MODULE__{recurso | cantidad_disponible: cantidad}}
  end

  def verificar_cantidad_disponible(cantidad_disponible, cantidad_solicitada) when cantidad_disponible < cantidad_solicitada do
    {:error, "No hay suficiente cantidad disponible"}
  end

  def verificar_cantidad_disponible(cantidad_disponible, cantidad_solicitada) when cantidad_disponible >= cantidad_solicitada do
    {:ok, "Cantidad disponible suficiente"}
  end

end
