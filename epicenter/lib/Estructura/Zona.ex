defmodule Epicenter.Zona do
  @niveles [:critico, :alto, :medio, :bajo]

  @enforce_keys [:codigo, :nombre, :nivel]
  defstruct [:codigo, :nombre, :nivel]

  def nuevo(_codigo, "", _nivel), do: {:error, :nombre_vacio}

  def nuevo(codigo, nombre, nivel) when nivel in @niveles do
    {:ok, %__MODULE__{codigo: codigo, nombre: nombre, nivel: nivel}}
  end

  def nuevo(_codigo, _nombre, _nivel), do: {:error, :nivel_invalido}

  def cambiar_nivel(%__MODULE__{} = zona, nivel) when nivel in @niveles do
    {:ok, %{zona | nivel: nivel}}
  end

  def cambiar_nivel(_zona, _nivel), do: {:error, :nivel_invalido}
end
