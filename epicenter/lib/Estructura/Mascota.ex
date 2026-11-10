defmodule Epicenter.Mascota do
  @moduledoc """
  Reporte de una mascota perdida o encontrada.

  Es una estructura de datos con funciones puras: no usa procesos, no lee
  archivos y no consulta otros módulos. Las situaciones esperadas se devuelven
  como `{:ok, valor}` o `{:error, motivo}`, donde el motivo es un átomo
  (misma convención de `Epicenter.Zona`).

  ## Campos
    - id: identificador del reporte (por ejemplo "M001"); lo asigna el gestor.
    - tipo: `:perdida` o `:encontrada`.
    - especie: texto en minúsculas ("perro", "gato").
    - nombre: texto o `nil` si no se conoce.
    - caracteristicas: texto libre (puede estar vacío).
    - color: texto en minúsculas.
    - tamaño: `:pequeno`, `:mediano` o `:grande`.
    - zona: código de la zona donde se perdió o se encontró.
    - contacto: teléfono o persona de contacto.
    - estado: `:activa`, `:posible_coincidencia` o `:resuelta`.
    - coincidencia_con: id del reporte con el que hay posible coincidencia.

  ## Transiciones de estado válidas
    - `:activa` -> `:posible_coincidencia` o `:resuelta`
    - `:posible_coincidencia` -> `:activa` (se descarta) o `:resuelta`
    - `:resuelta` no cambia más: cerrarla otra vez es un error.
  """

  @tipos [:perdida, :encontrada]
  @estados [:activa, :posible_coincidencia, :resuelta]
  @tamanos [:pequeno, :mediano, :grande]

  @transiciones %{
    activa: [:posible_coincidencia, :resuelta],
    posible_coincidencia: [:activa, :resuelta],
    resuelta: []
  }

  @enforce_keys [:id, :tipo, :especie, :color, :tamano, :zona, :contacto]
  defstruct [
    :id,
    :tipo,
    :especie,
    :nombre,
    :caracteristicas,
    :color,
    :tamano,
    :zona,
    :contacto,
    :coincidencia_con,
    estado: :activa
  ]

  @type t :: %__MODULE__{}

  @doc "Tipos de reporte válidos."
  def tipos, do: @tipos

  @doc "Estados válidos de un reporte."
  def estados, do: @estados

  @doc "Tamaños válidos."
  def tamanos, do: @tamanos

  @doc """
  Crea un reporte validando y normalizando los datos recibidos.

  Devuelve `{:ok, mascota}` o `{:error, motivo}`. Motivos posibles:
  `:tipo_invalido`, `:especie_vacia`, `:color_vacio`, `:tamano_invalido`,
  `:zona_vacia`, `:contacto_vacio` y `:datos_invalidos`.

  ## Parámetros
    - id: identificador del reporte (texto).
    - datos: mapa con las claves `:tipo`, `:especie`, `:color`, `:tamano`,
      `:zona` y `:contacto` (obligatorias) y `:nombre` y `:caracteristicas`
      (opcionales). El tipo y el tamaño pueden llegar como átomo o como texto.

  ## Ejemplo

      iex> datos = %{tipo: "lost", especie: "Perro", color: "Negra",
      ...>           tamano: "mediana", zona: "zona_norte", contacto: "300 123 4567"}
      iex> {:ok, mascota} = Epicenter.Mascota.nuevo("M001", datos)
      iex> {mascota.tipo, mascota.especie, mascota.tamano, mascota.estado}
      {:perdida, "perro", :mediano, :activa}

  """
  @spec nuevo(String.t(), map()) :: {:ok, t()} | {:error, atom()}
  def nuevo(id, datos) when is_binary(id) and is_map(datos) do
    with {:ok, tipo} <- validar_tipo(Map.get(datos, :tipo)),
         {:ok, especie} <- obligatorio(Map.get(datos, :especie), :especie_vacia),
         {:ok, color} <- obligatorio(Map.get(datos, :color), :color_vacio),
         {:ok, tamano} <- normalizar_tamano(Map.get(datos, :tamano)),
         {:ok, zona} <- obligatorio(Map.get(datos, :zona), :zona_vacia),
         {:ok, contacto} <- obligatorio(Map.get(datos, :contacto), :contacto_vacio) do
      {:ok,
       %__MODULE__{
         id: id,
         tipo: tipo,
         especie: String.downcase(especie),
         nombre: normalizar_nombre(Map.get(datos, :nombre)),
         caracteristicas: texto_opcional(Map.get(datos, :caracteristicas)),
         color: String.downcase(color),
         tamano: tamano,
         zona: zona,
         contacto: contacto
       }}
    end
  end

  def nuevo(_id, _datos), do: {:error, :datos_invalidos}

  @doc """
  Cambia el estado de un reporte si la transición es válida.

  Devuelve `{:ok, mascota}` o `{:error, motivo}`:
    - `:ya_resuelta`: el reporte ya estaba cerrado (no se cierra dos veces).
    - `:transicion_invalida`: el cambio no está permitido desde el estado actual.
    - `:estado_invalido`: el estado pedido no existe.
  """
  @spec cambiar_estado(t(), atom()) :: {:ok, t()} | {:error, atom()}
  def cambiar_estado(%__MODULE__{estado: actual} = mascota, nuevo_estado)
      when nuevo_estado in @estados do
    cond do
      actual == :resuelta ->
        {:error, :ya_resuelta}

      nuevo_estado in Map.fetch!(@transiciones, actual) ->
        {:ok, %{mascota | estado: nuevo_estado}}

      true ->
        {:error, :transicion_invalida}
    end
  end

  def cambiar_estado(%__MODULE__{}, _estado), do: {:error, :estado_invalido}

  # --- Validaciones y normalización (funciones privadas y puras) ---

  # El tipo llega como átomo (desde el código) o como texto (comandos y formularios).
  defp validar_tipo(tipo) when tipo in @tipos, do: {:ok, tipo}

  defp validar_tipo(tipo) when is_binary(tipo) do
    case tipo |> String.trim() |> String.downcase() do
      texto when texto in ["perdida", "perdido", "lost"] -> {:ok, :perdida}
      texto when texto in ["encontrada", "encontrado", "found"] -> {:ok, :encontrada}
      _otro -> {:error, :tipo_invalido}
    end
  end

  defp validar_tipo(_tipo), do: {:error, :tipo_invalido}

  # Texto obligatorio: no puede ser vacío ni llegar con otro tipo de dato.
  defp obligatorio(texto, motivo) when is_binary(texto) do
    case String.trim(texto) do
      "" -> {:error, motivo}
      recortado -> {:ok, recortado}
    end
  end

  defp obligatorio(_texto, motivo), do: {:error, motivo}

  # Acepta "pequeño", "pequeña", "pequeno", "mediano", "mediana" y "grande".
  defp normalizar_tamano(tamano) when tamano in @tamanos, do: {:ok, tamano}

  defp normalizar_tamano(tamano) when is_binary(tamano) do
    case tamano |> String.trim() |> String.downcase() |> String.replace("ñ", "n") do
      texto when texto in ["pequeno", "pequena"] -> {:ok, :pequeno}
      texto when texto in ["mediano", "mediana"] -> {:ok, :mediano}
      "grande" -> {:ok, :grande}
      _otro -> {:error, :tamano_invalido}
    end
  end

  defp normalizar_tamano(_tamano), do: {:error, :tamano_invalido}

  # Un nombre vacío o "desconocido" significa que no se conoce el nombre.
  defp normalizar_nombre(nombre) when is_binary(nombre) do
    case String.trim(nombre) do
      "" -> nil
      texto -> if String.downcase(texto) == "desconocido", do: nil, else: texto
    end
  end

  defp normalizar_nombre(_nombre), do: nil

  defp texto_opcional(texto) when is_binary(texto), do: String.trim(texto)
  defp texto_opcional(_texto), do: ""
end
#hoL
