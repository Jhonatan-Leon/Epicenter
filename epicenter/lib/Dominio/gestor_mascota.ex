defmodule Epicenter.GestorMascota do
  @moduledoc """
  Gestor de reportes de mascotas: CRUD, persistencia y coincidencias entre
  mascotas perdidas y encontradas.

  ## Puntaje de similitud (0 a 100)

  | Atributo        | Peso | Criterio                                                      |
  |-----------------|------|---------------------------------------------------------------|
  | especie         | 30   | igual = 30. Si difiere, el par se descarta (puntaje 0)        |
  | color           | 20   | igual = 20; uno contenido en el otro = 10                     |
  | zona            | 20   | igual = 20                                                    |
  | tamaño          | 15   | igual = 15; adyacente (pequeño-mediano, mediano-grande) = 7   |
  | características | 15   | similitud de Jaccard entre las palabras significativas        |

  ## Umbrales
    - 40 o más: el par es una coincidencia candidata (se muestra al usuario).
    - 70 o más: el par se marca como `:posible_coincidencia`.
  """

  @peso_especie 30
  @peso_color 20
  @peso_zona 20
  @peso_tamano 15
  @peso_caracteristicas 15

  @umbral_candidata 40
  @umbral_marcar 70

  @indice_tamano %{pequeno: 0, mediano: 1, grande: 2}

  # Palabras que no aportan al comparar características.
  @palabras_vacias ~w(con sin del los las una por para que muy)

  def listar, do: Epicenter.Persistencia.cargar_mascotas()

  def registro(datos) when is_map(datos) do
    registro(Utilidad.generar_codigo_unico(), datos)
  end

  def registro(_datos), do: {:error, "Los datos de la mascota deben ser un mapa"}

  def registro(id, datos) do
    with {:ok, mascota} <- Epicenter.Mascota.nuevo(id, datos),
         {:ok, mascota} <- crear(mascota) do
      {:ok, mascota}
    end
  end

  def obtener(id) do
    with {:ok, mascotas} <- listar() do
      case Enum.find(mascotas, &(&1.id == id)) do
        nil -> {:error, "Mascota no encontrada"}
        mascota -> {:ok, mascota}
      end
    end
  end

  def crear(%Epicenter.Mascota{} = mascota) do
    with {:ok, mascotas} <- listar() do
      if Enum.any?(mascotas, &(&1.id == mascota.id)) do
        {:error, "La mascota ya existe"}
      else
        Epicenter.Persistencia.guardar_mascotas([mascota | mascotas])
        {:ok, mascota}
      end
    end
  end

  def crear(_), do: {:error, "La mascota no es válida"}

  def actualizar(id, %Epicenter.Mascota{id: id} = mascota) do
    with {:ok, mascotas} <- listar() do
      if Enum.any?(mascotas, &(&1.id == id)) do
        Epicenter.Persistencia.guardar_mascotas(
          Enum.map(mascotas, fn existente ->
            if existente.id == id, do: mascota, else: existente
          end)
        )

        {:ok, mascota}
      else
        {:error, "Mascota no encontrada"}
      end
    end
  end

  def actualizar(_id, _mascota), do: {:error, "La mascota no es válida"}

  def cambiar_estado(id, nuevo_estado) do
    with {:ok, mascotas} <- listar(),
         {:ok, mascota} <- buscar_mascota(mascotas, id),
         {:ok, mascota_actualizada} <- Epicenter.Mascota.cambiar_estado(mascota, nuevo_estado) do
      guardar_actualizacion(mascotas, mascota_actualizada)
    end
  end

  def eliminar(id) do
    with {:ok, mascotas} <- listar() do
      case Enum.find(mascotas, &(&1.id == id)) do
        nil ->
          {:error, "Mascota no encontrada"}

        mascota ->
          Epicenter.Persistencia.guardar_mascotas(Enum.reject(mascotas, &(&1.id == id)))
          {:ok, mascota}
      end
    end
  end

  @doc """
  Consulta reportes por especie, zona y estado, solos o combinados.

  Los filtros llegan como lista de claves o como mapa, por ejemplo
  `consultar(especie: "perro", zona: "zona_norte", estado: :activa)`. Sin filtros
  devuelve todos los reportes. El estado puede ser átomo o texto, y la especie no
  distingue mayúsculas.

  Devuelve `{:ok, reportes}` (lista vacía si nada coincide) o `{:error, motivo}`:
  `:filtro_invalido` (clave desconocida o valor que no es texto),
  `:estado_invalido` o `:filtros_invalidos` (no son una lista ni un mapa).
  """
  def consultar(filtros \\ [])

  def consultar(filtros) when is_list(filtros) or is_map(filtros) do
    with {:ok, filtros} <- normalizar_filtros(filtros),
         {:ok, mascotas} <- listar() do
      {:ok, filtrar(mascotas, filtros)}
    end
  end

  def consultar(_filtros), do: {:error, :filtros_invalidos}

  defp normalizar_filtros(filtros) do
    Enum.reduce_while(filtros, {:ok, []}, fn {clave, valor}, {:ok, normalizados} ->
      case normalizar_filtro(clave, valor) do
        {:ok, filtro} -> {:cont, {:ok, [filtro | normalizados]}}
        {:error, _motivo} = error -> {:halt, error}
      end
    end)
  end

  defp normalizar_filtro(:especie, valor) when is_binary(valor),
    do: {:ok, {:especie, valor |> String.trim() |> String.downcase()}}

  defp normalizar_filtro(:zona, valor) when is_binary(valor),
    do: {:ok, {:zona, String.trim(valor)}}

  defp normalizar_filtro(:estado, valor) do
    case Enum.find(Epicenter.Mascota.estados(), &(&1 == valor or Atom.to_string(&1) == valor)) do
      nil -> {:error, :estado_invalido}
      estado -> {:ok, {:estado, estado}}
    end
  end

  defp normalizar_filtro(_clave, _valor), do: {:error, :filtro_invalido}

  # Un reporte pasa si cumple todos los filtros.
  defp filtrar(mascotas, filtros) do
    Enum.filter(mascotas, fn mascota ->
      Enum.all?(filtros, fn {campo, valor} -> Map.fetch!(mascota, campo) == valor end)
    end)
  end

  @doc """
  Coincidencias candidatas (puntaje de 40 o más) entre reportes perdidos y
  encontrados no resueltos, de mayor a menor puntaje. No modifica nada.
  """
  def coincidencias_posibles do
    with {:ok, mascotas} <- listar() do
      {:ok, calcular_coincidencias(mascotas)}
    end
  end

  @doc """
  Marca como `:posible_coincidencia` las parejas de reportes activos con puntaje
  de 70 o más. Cada reporte queda en una sola pareja y guarda en
  `coincidencia_con` el id de la otra. Devuelve `{:ok, parejas_marcadas}`.
  """
  def marcar_coincidencias do
    with {:ok, mascotas} <- listar() do
      parejas =
        mascotas
        |> Enum.filter(&(&1.estado == :activa))
        |> calcular_coincidencias()
        |> seleccionar_para_marcar()

      if parejas != [] do
        vinculos =
          Enum.reduce(parejas, %{}, fn par, acc ->
            acc |> Map.put(par.perdida, par.encontrada) |> Map.put(par.encontrada, par.perdida)
          end)

        actualizadas =
          Enum.map(mascotas, fn mascota ->
            case Map.fetch(vinculos, mascota.id) do
              {:ok, otro_id} -> marcar(mascota, otro_id)
              :error -> mascota
            end
          end)

        Epicenter.Persistencia.guardar_mascotas(actualizadas)
      end

      {:ok, parejas}
    end
  end

  @doc """
  Confirma una coincidencia: cierra (`:resuelta`) el reporte de la mascota perdida
  y el de la encontrada, y deja en cada uno el id del otro en `coincidencia_con`.

  Es todo o nada: si alguno de los dos no se puede cerrar (por ejemplo, ya estaba
  resuelto) no se guarda ningún cambio. Devuelve `{:ok, {perdida, encontrada}}`.
  """
  def confirmar_coincidencia(id_perdida, id_encontrada) do
    with {:ok, mascotas} <- listar(),
         {:ok, perdida} <- buscar_mascota(mascotas, id_perdida),
         {:ok, encontrada} <- buscar_mascota(mascotas, id_encontrada),
         :ok <- validar_tipos(perdida, encontrada),
         {:ok, perdida_cerrada} <- cerrar(perdida, encontrada.id),
         {:ok, encontrada_cerrada} <- cerrar(encontrada, perdida.id) do
      reemplazos = %{
        perdida_cerrada.id => perdida_cerrada,
        encontrada_cerrada.id => encontrada_cerrada
      }

      Epicenter.Persistencia.guardar_mascotas(
        Enum.map(mascotas, fn mascota -> Map.get(reemplazos, mascota.id, mascota) end)
      )

      {:ok, {perdida_cerrada, encontrada_cerrada}}
    end
  end

  # ===== Lógica pura de coincidencias (no leen ni escriben archivos) =====

  @doc "Puntaje mínimo para considerar un par como coincidencia candidata."
  def umbral_candidata, do: @umbral_candidata

  @doc "Puntaje mínimo para marcar un par como posible coincidencia."
  def umbral_marcar, do: @umbral_marcar

  @doc "Peso máximo de cada atributo en el puntaje."
  def pesos do
    %{
      especie: @peso_especie,
      color: @peso_color,
      zona: @peso_zona,
      tamano: @peso_tamano,
      caracteristicas: @peso_caracteristicas
    }
  end

  @doc """
  Puntos que aporta cada atributo al comparar dos reportes.

  Si las especies son distintas, todos los atributos valen 0.
  """
  @spec desglose(Epicenter.Mascota.t(), Epicenter.Mascota.t()) :: map()
  def desglose(%Epicenter.Mascota{especie: especie} = a, %Epicenter.Mascota{especie: especie} = b) do
    %{
      especie: @peso_especie,
      color: puntos_color(a.color, b.color),
      zona: if(a.zona == b.zona, do: @peso_zona, else: 0),
      tamano: puntos_tamano(a.tamano, b.tamano),
      caracteristicas: puntos_caracteristicas(a.caracteristicas, b.caracteristicas)
    }
  end

  def desglose(%Epicenter.Mascota{}, %Epicenter.Mascota{}) do
    %{especie: 0, color: 0, zona: 0, tamano: 0, caracteristicas: 0}
  end

  @doc "Puntaje total de similitud entre dos reportes (0 a 100)."
  @spec puntaje(Epicenter.Mascota.t(), Epicenter.Mascota.t()) :: non_neg_integer()
  def puntaje(%Epicenter.Mascota{} = a, %Epicenter.Mascota{} = b), do: a |> desglose(b) |> suma()

  @doc """
  Calcula las coincidencias candidatas entre todas las mascotas perdidas y
  encontradas de la lista, ordenadas de mayor a menor puntaje.

  Se ignoran los reportes ya resueltos. Cada elemento del resultado es un mapa
  `%{perdida: id, encontrada: id, puntaje: n, desglose: %{...}}`.
  """
  @spec calcular_coincidencias([Epicenter.Mascota.t()], non_neg_integer()) :: [map()]
  def calcular_coincidencias(mascotas, umbral \\ @umbral_candidata) when is_list(mascotas) do
    perdidas = Enum.filter(mascotas, &(&1.tipo == :perdida and &1.estado != :resuelta))
    encontradas = Enum.filter(mascotas, &(&1.tipo == :encontrada and &1.estado != :resuelta))

    perdidas
    |> comparar_con_todas(encontradas, umbral, [])
    |> Enum.sort_by(&{-&1.puntaje, &1.perdida, &1.encontrada})
  end

  @doc """
  Elige las parejas que se van a marcar como posible coincidencia.

  Recibe las coincidencias ya ordenadas por puntaje. Solo se consideran las que
  alcanzan el umbral y cada reporte queda en una sola pareja: la de mayor puntaje.
  """
  @spec seleccionar_para_marcar([map()], non_neg_integer()) :: [map()]
  def seleccionar_para_marcar(coincidencias, umbral \\ @umbral_marcar) do
    coincidencias
    |> Enum.filter(&(&1.puntaje >= umbral))
    |> elegir([], MapSet.new())
  end

  # --- Recursión ---

  # Recorre las perdidas y compara cada una con todas las encontradas.
  defp comparar_con_todas([], _encontradas, _umbral, acumuladas), do: acumuladas

  defp comparar_con_todas([perdida | resto], encontradas, umbral, acumuladas) do
    nuevas = emparejar(perdida, encontradas, umbral)
    comparar_con_todas(resto, encontradas, umbral, nuevas ++ acumuladas)
  end

  # Compara una perdida con cada encontrada y se queda con las que llegan al umbral.
  defp emparejar(_perdida, [], _umbral), do: []

  defp emparejar(perdida, [encontrada | resto], umbral) do
    desglose = desglose(perdida, encontrada)
    puntaje = suma(desglose)
    siguientes = emparejar(perdida, resto, umbral)

    if puntaje >= umbral do
      [
        %{perdida: perdida.id, encontrada: encontrada.id, puntaje: puntaje, desglose: desglose}
        | siguientes
      ]
    else
      siguientes
    end
  end

  # Recorre las coincidencias de mayor a menor puntaje; un reporte ya usado no se repite.
  defp elegir([], elegidas, _usados), do: Enum.reverse(elegidas)

  defp elegir([par | resto], elegidas, usados) do
    if MapSet.member?(usados, par.perdida) or MapSet.member?(usados, par.encontrada) do
      elegir(resto, elegidas, usados)
    else
      usados = usados |> MapSet.put(par.perdida) |> MapSet.put(par.encontrada)
      elegir(resto, [par | elegidas], usados)
    end
  end

  # --- Puntos por atributo ---

  defp suma(desglose), do: desglose |> Map.values() |> Enum.sum()

  # "negra" y "negro" comparten raíz; "negro con blanco" contiene a "negro".
  defp puntos_color(a, b) do
    raiz_a = raiz_color(a)
    raiz_b = raiz_color(b)

    cond do
      raiz_a == "" or raiz_b == "" -> 0
      raiz_a == raiz_b -> @peso_color
      String.contains?(raiz_a, raiz_b) or String.contains?(raiz_b, raiz_a) -> div(@peso_color, 2)
      true -> 0
    end
  end

  defp raiz_color(color), do: color |> normalizar() |> String.replace(~r/(os|as|o|a)$/, "")

  defp puntos_tamano(a, b) do
    case abs(Map.fetch!(@indice_tamano, a) - Map.fetch!(@indice_tamano, b)) do
      0 -> @peso_tamano
      1 -> div(@peso_tamano, 2)
      _ -> 0
    end
  end

  # Similitud de Jaccard: palabras en común / palabras distintas en total.
  defp puntos_caracteristicas(a, b) do
    palabras_a = palabras(a)
    palabras_b = palabras(b)
    total = palabras_a |> MapSet.union(palabras_b) |> MapSet.size()

    if total == 0 do
      0
    else
      comunes = palabras_a |> MapSet.intersection(palabras_b) |> MapSet.size()
      round(@peso_caracteristicas * comunes / total)
    end
  end

  defp palabras(texto) do
    texto
    |> normalizar()
    |> String.split(~r/[^a-z0-9]+/, trim: true)
    |> Enum.filter(fn palabra ->
      String.length(palabra) >= 3 and palabra not in @palabras_vacias
    end)
    |> MapSet.new()
  end

  # Minúsculas y sin tildes, para que "caída" y "caida" cuenten como iguales.
  defp normalizar(texto) when is_binary(texto) do
    texto
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.trim()
  end

  defp normalizar(_otro), do: ""

  defp marcar(mascota, otro_id) do
    case Epicenter.Mascota.cambiar_estado(mascota, :posible_coincidencia) do
      {:ok, marcada} -> %{marcada | coincidencia_con: otro_id}
      {:error, _motivo} -> mascota
    end
  end

  defp cerrar(mascota, otro_id) do
    with {:ok, cerrada} <- Epicenter.Mascota.cambiar_estado(mascota, :resuelta) do
      {:ok, %{cerrada | coincidencia_con: otro_id}}
    end
  end

  defp validar_tipos(%Epicenter.Mascota{tipo: :perdida}, %Epicenter.Mascota{tipo: :encontrada}),
    do: :ok

  defp validar_tipos(_perdida, _encontrada), do: {:error, :tipos_incompatibles}

  defp buscar_mascota(mascotas, id) do
    case Enum.find(mascotas, &(&1.id == id)) do
      nil -> {:error, "Mascota no encontrada"}
      mascota -> {:ok, mascota}
    end
  end

  defp guardar_actualizacion(mascotas, mascota_actualizada) do
    Epicenter.Persistencia.guardar_mascotas(
      Enum.map(mascotas, fn existente ->
        if existente.id == mascota_actualizada.id, do: mascota_actualizada, else: existente
      end)
    )

    {:ok, mascota_actualizada}
  end
end
