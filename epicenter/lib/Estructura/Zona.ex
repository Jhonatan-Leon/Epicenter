defmodule Epicenter.Zona do
  @niveles [:critico, :alto, :medio, :bajo]

  @enforce_keys [:codigo, :nombre, :nivel]
    defstruct [:codigo, :nombre, :nivel, sectores: []]

  def nuevo(_codigo, "", _nivel), do: {:error, :nombre_vacio}

  def nuevo(codigo, nombre, nivel) when nivel in @niveles do
    {:ok, %__MODULE__{codigo: codigo, nombre: nombre, nivel: nivel}}
  end

  def nuevo(_codigo, _nombre, _nivel), do: {:error, :nivel_invalido}

  def cambiar_nivel(%__MODULE__{} = zona, nivel) when nivel in @niveles do
    {:ok, %{zona | nivel: nivel}}
  end

  def cambiar_nivel(_zona, _nivel), do: {:error, :nivel_invalido}

  def agregar_sector(%__MODULE__{} = zona, sector) do
    if Enum.any?(zona.sectores, fn s -> s.nombre == sector.nombre end),
      do: {:error, :sector_duplicado},
      else: {:ok, %{zona | sectores: zona.sectores ++ [sector]}}
  end

  # func recursiva: busca un sector por código
  def buscar_sector(%__MODULE__{sectores: sectores}, codigo), do: buscar(sectores, codigo)

  defp buscar([], _codigo), do: {:error, :sector_no_encontrado}
  defp buscar([%{codigo: codigo} = sector | _resto], codigo), do: {:ok, sector}
  defp buscar([_otro | resto], codigo), do: buscar(resto, codigo)

  # func recursiva: devuelve la zona con un sector reemplazado (inmutabilidad)
  def actualizar_sector(%__MODULE__{} = zona, sector),
    do: %{zona | sectores: reemplazar(zona.sectores, sector)}

  defp reemplazar([], _nuevo), do: []
  defp reemplazar([%{codigo: c} | resto], %{codigo: c} = nuevo), do: [nuevo | resto]
  defp reemplazar([sector | resto], nuevo), do: [sector | reemplazar(resto, nuevo)]

  # func recursiva: personas afectadas de la zona = suma de sus sectores
  def total_afectadas(%__MODULE__{sectores: sectores}), do: sumar_afectadas(sectores)

  defp sumar_afectadas([]), do: 0
  defp sumar_afectadas([sector | resto]), do: sector.afectadas + sumar_afectadas(resto)

  # func recursiva: cuántos puntos de atención tiene la zona
  def total_puntos(%__MODULE__{sectores: sectores}), do: contar_puntos(sectores)

  defp contar_puntos([]), do: 0
  defp contar_puntos([sector | resto]), do: length(sector.puntos) + contar_puntos(resto)

end
