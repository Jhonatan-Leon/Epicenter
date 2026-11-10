defmodule Epicenter.Sector do
  @niveles [:critico, :alto, :medio, :bajo]

  @enforce_keys [:codigo, :nombre, :nivel]
  defstruct [:codigo, :nombre, :nivel, afectadas: 0, puntos: []]

  def nuevo(_codigo, "", _nivel, _afectadas), do: {:error, :nombre_vacio}

  def nuevo(codigo, nombre, nivel, afectadas)
      when nivel in @niveles and is_integer(afectadas) and afectadas >= 0 do
    {:ok, %__MODULE__{codigo: codigo, nombre: nombre, nivel: nivel, afectadas: afectadas}}
  end

  def nuevo(_codigo, _nombre, nivel, _afectadas) when nivel not in @niveles,
    do: {:error, :nivel_invalido}

  def nuevo(_codigo, _nombre, _nivel, _afectadas), do: {:error, :afectadas_invalidas}

  def agregar_punto(%__MODULE__{} = sector, punto) do
    if Enum.any?(sector.puntos, fn p -> p.nombre == punto.nombre end),
      do: {:error, :punto_duplicado},
      else: {:ok, %{sector | puntos: sector.puntos ++ [punto]}}
  end
end
