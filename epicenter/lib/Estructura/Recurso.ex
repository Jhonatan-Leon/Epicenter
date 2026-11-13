defmodule Epicenter.Recurso do
  @moduledoc """
  """
  @categorias [:agua, :alimentos, :medicamentos, :abrigo, :higiene, :otros]

  @enforce_keys [:codigo, :nombre, :categoria, :unidad_medida, :ubicacion]
  defstruct [
    :codigo,
    :nombre,
    :categoria,
    :unidad_medida,
    :ubicacion,
    :codigo_zona,
    cantidad_disponible: 0,
    minimo: 0
  ]

  def categorias, do: @categorias

  # Crea el recurso validando la categoría y que las cantidades no sean negativas
  def nuevo(datos) when is_map(datos) do
    cond do
      datos.categoria not in @categorias ->
        {:error, :categoria_invalida}

      not cantidad_valida?(datos.cantidad) or not cantidad_valida?(datos.minimo) ->
        {:error, :cantidad_invalida}

      true ->
        {:ok,
         %__MODULE__{
           codigo: datos.codigo,
           nombre: datos.nombre,
           categoria: datos.categoria,
           unidad_medida: datos.unidad_medida,
           ubicacion: datos.ubicacion,
           codigo_zona: datos.codigo_zona,
           cantidad_disponible: datos.cantidad,
           minimo: datos.minimo
         }}
    end
  end

  # Suma unidades al recurso (entrada de inventario)
  def agregar(%__MODULE__{} = recurso, cantidad) when is_integer(cantidad) and cantidad > 0 do
    {:ok, %__MODULE__{recurso | cantidad_disponible: recurso.cantidad_disponible + cantidad}}
  end

  def agregar(_recurso, _cantidad), do: {:error, :cantidad_invalida}

  # Resta unidades solo si alcanzan
  def retirar(%__MODULE__{cantidad_disponible: disponible} = recurso, cantidad)
      when is_integer(cantidad) and cantidad > 0 and cantidad <= disponible do
    {:ok, %__MODULE__{recurso | cantidad_disponible: disponible - cantidad}}
  end

  def retirar(%__MODULE__{}, cantidad) when is_integer(cantidad) and cantidad > 0,
    do: {:error, :sin_existencias}

  def retirar(_recurso, _cantidad), do: {:error, :cantidad_invalida}

  # Un recurso es critico cuando está por debajo de su mínimo
  def critico?(%__MODULE__{cantidad_disponible: disponible, minimo: minimo}),
    do: disponible < minimo

  defp cantidad_valida?(cantidad), do: is_integer(cantidad) and cantidad >= 0
end
