defmodule Epicenter.GestorZonas do
  alias Epicenter.{Zona, Sector, PuntoAtencion}

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

  def registrar_sector(zonas, codigo_zona, nombre, nivel, afectadas) do
    with {:ok, zona} <- obtener(zonas, codigo_zona),
         {:ok, sector} <- Sector.nuevo(Utilidad.generar_codigo_unico(), nombre, nivel, afectadas),
         {:ok, zona} <- Zona.agregar_sector(zona, sector) do
      {:ok, Map.put(zonas, codigo_zona, zona)}
    end
  end

  def registrar_punto(zonas, codigo_zona, codigo_sector, nombre) do
    with {:ok, zona} <- obtener(zonas, codigo_zona),
         {:ok, sector} <- Zona.buscar_sector(zona, codigo_sector),
         {:ok, punto} <- PuntoAtencion.nuevo(Utilidad.generar_codigo_unico(), nombre),
         {:ok, sector} <- Sector.agregar_punto(sector, punto) do
      {:ok, Map.put(zonas, codigo_zona, Zona.actualizar_sector(zona, sector))}
    end
  end

  def estadisticas(zonas, codigo_zona) do
    with {:ok, zona} <- obtener(zonas, codigo_zona) do
      {:ok,
       %{
         nombre: zona.nombre,
         nivel: zona.nivel,
         sectores: length(zona.sectores),
         puntos: Zona.total_puntos(zona),
         afectadas: Zona.total_afectadas(zona)
       }}
    end
  end
end
