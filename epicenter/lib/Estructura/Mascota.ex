defmodule Epicenter.Mascota do
  @moduledoc """
  """
  @estado_minimo [:activa, :posible_coincidencia, :resuelta]
  @enforce_keys [:id, :nombre, :tipo, :codigo_zona]
  defstruct [:id, :nombre, :tipo, :codigo_zona, :especie, :carateristicas, :color, :tamano, :contacto, :estado]

  def nuevo(id, nombre, tipo, codigo_zona, especie, carateristicas, color, tamano, contacto, estado) do
    {:ok, %__MODULE__{id: Utilidad.generar_codigo_unico(), nombre: nombre, tipo: verificar_tipo(tipo), codigo_zona: verificar_zona(codigo_zona), especie: especie, carateristicas: carateristicas, color: color, tamano: tamano, contacto: contacto, estado: verificar_estado_minimo(estado) }}
  end


  def verificar_tipo(estado) do
    case estado do
      :perdido -> {:ok, :perdido}
      :encontrado -> {:ok, :encontrado}
      _ -> {:error, "Estado inválido"}
    end
  end

  def verificar_zona(codigo_zona) do
    case Epicenter.Zona.nueva(codigo_zona) do
      {:ok, _zona} -> {:ok, codigo_zona}
      {:error, _} -> {:error, "Zona inválida"}
    end
  end

  def verificar_estado_minimo(estado) do
    if estado in @estado_minimo do
      {:ok, estado}
    else
      {:error, "Estado inválido"}
    end
  end
end
