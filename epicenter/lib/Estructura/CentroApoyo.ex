defmodule Epicenter.CentroApoyo do
  @moduledoc """
  """
  @enforce_keys [:nombre, :tipo]
  defstruct [:codigo, :nombre, :tipo, :codigo_zona]

  def nuevo(nombre, tipo) do
    {:ok, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), nombre: nombre, tipo: tipo}}
  end

  def nuevo(nombre, tipo, codigo_zona) do
    {:ok,
     %__MODULE__{
       codigo: Utilidad.generar_codigo_unico(),
       nombre: nombre,
       tipo: tipo,
       codigo_zona: codigo_zona
     }}
  end

  def completar_centro_apoyo(%__MODULE__{} = centro, codigo_zona) do
    {:ok, %__MODULE__{centro | codigo_zona: codigo_zona}}
  end
end
