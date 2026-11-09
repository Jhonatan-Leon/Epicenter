defmodule Epicenter.GestorZonas do
  alias Epicenter.Zona

  def registrar(zonas, nombre, nivel) do
    codigo = generar_codigo(zonas)

    with :ok <- verificar_nombre_libre(zonas, nombre),
         {:ok, zona} <- Zona.nuevo(codigo, nombre, nivel) do
      {:ok, Map.put(zonas, codigo, zona)}
    end
  end

  def obtener(zonas, codigo) do
    case Map.get(zonas, codigo) do
      nil -> {:error, :no_encontrada}
      zona -> {:ok, zona}
    end
  end

  def cambiar_nivel(zonas, codigo, nivel) do
    with {:ok, zona} <- obtener(zonas, codigo),
         {:ok, zona} <- Zona.cambiar_nivel(zona, nivel) do
      {:ok, Map.put(zonas, codigo, zona)}
    end
  end

  def eliminar(zonas, codigo) do
    if Map.has_key?(zonas, codigo),
      do: {:ok, Map.delete(zonas, codigo)},
      else: {:error, :no_encontrada}
  end

  def listar(zonas), do: Map.values(zonas)

  defp verificar_nombre_libre(zonas, nombre) do
    if Enum.any?(Map.values(zonas), fn zona -> zona.nombre == nombre end),
      do: {:error, :nombre_duplicado},
      else: :ok
  end

  # Si el código ya existe, pide otro
  defp generar_codigo(zonas) do
    codigo = Utilidad.generar_codigo_unico()
    if Map.has_key?(zonas, codigo), do: generar_codigo(zonas), else: codigo
  end
end
