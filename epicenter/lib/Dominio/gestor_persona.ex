defmodule Epicenter.GestorPersona do
  def listar, do: Epicenter.Persistencia.cargar_personas()

  def registro(documento, tipo_documento, nombre, codigo_zona, codigo_albergue) do
    with {:ok, persona} <-
           Epicenter.Persona.nuevo(
             documento,
             tipo_documento,
             nombre,
             codigo_zona,
             codigo_albergue
           ),
         {:ok, persona} <- crear(persona) do
      {:ok, persona}
    end
  end

  def registro(
        documento,
        tipo_documento,
        nombre,
        edad,
        codigo_zona,
        estado,
        codigo_albergue,
        historial
      ) do
    with {:ok, persona} <-
           Epicenter.Persona.nuevo(
             documento,
             tipo_documento,
             nombre,
             edad,
             codigo_zona,
             estado,
             codigo_albergue,
             historial
           ),
         {:ok, persona} <- crear(persona) do
      {:ok, persona}
    end
  end

  def completar_informacion(id, edad, estado, historial) do
    with {:ok, personas} <- listar(),
         {:ok, persona} <- buscar_persona(personas, id),
         {:ok, persona_actualizada} <-
           Epicenter.Persona.completar_persona(persona, edad, estado, historial) do
      personas_actualizadas =
        Enum.map(personas, fn existente ->
          if existente.id == id, do: persona_actualizada, else: existente
        end)

      Epicenter.Persistencia.guardar_personas(personas_actualizadas)
      {:ok, persona_actualizada}
    end
  end

  def obtener(id) do
    with {:ok, personas} <- listar() do
      case Enum.find(personas, &(&1.id == id)) do
        nil -> {:error, "Persona no encontrada"}
        persona -> {:ok, persona}
      end
    end
  end

  def crear(%Epicenter.Persona{} = persona) do
    with {:ok, personas} <- listar() do
      if Enum.any?(personas, &(&1.id == persona.id)) do
        {:error, "La persona ya existe"}
      else
        Epicenter.Persistencia.guardar_personas([persona | personas])
        {:ok, persona}
      end
    end
  end

  def crear(_), do: {:error, "La persona no es válida"}

  def actualizar(id, %Epicenter.Persona{id: id} = persona) do
    with {:ok, personas} <- listar() do
      if Enum.any?(personas, &(&1.id == id)) do
        Epicenter.Persistencia.guardar_personas(
          Enum.map(personas, fn existente ->
            if existente.id == id, do: persona, else: existente
          end)
        )

        {:ok, persona}
      else
        {:error, "Persona no encontrada"}
      end
    end
  end

  def actualizar(_id, _persona), do: {:error, "La persona no es válida"}

  def eliminar(id) do
    with {:ok, personas} <- listar() do
      case Enum.find(personas, &(&1.id == id)) do
        nil ->
          {:error, "Persona no encontrada"}

        persona ->
          Epicenter.Persistencia.guardar_personas(Enum.reject(personas, &(&1.id == id)))
          {:ok, persona}
      end
    end
  end

  # ===== Comunicación entre familiares: reporte, búsqueda y cambios de estado =====

  # Estados a los que se puede pasar desde cada estado. `:reunificada` es final.
  @transiciones %{
    sin_informacion: [:reportada, :localizada],
    reportada: [:localizada, :trasladada, :en_albergue],
    localizada: [:trasladada, :en_albergue, :reunificada],
    trasladada: [:localizada, :en_albergue, :reunificada],
    en_albergue: [:trasladada, :reunificada],
    reunificada: []
  }

  @filtros_busqueda [:texto, :nombre, :documento, :zona, :estado]

  @doc """
  Reporta una persona afectada. Los datos pueden llegar como texto (por ejemplo
  la edad `"34"` o el estado `"reportada"`), como los envía la interfaz.

  Crea el primer registro del historial con el estado inicial y quién la reportó.
  Devuelve `{:ok, persona}` o `{:error, motivo}`: `:documento_vacio`,
  `:nombre_vacio`, `:edad_invalida` (entre 0 y 120), `:zona_vacia`,
  `:estado_invalido` o `:documento_duplicado`.
  """
  def reportar_persona(documento, nombre, edad, zona, estado, por \\ "sistema") do
    with {:ok, documento} <- texto_obligatorio(documento, :documento_vacio),
         {:ok, nombre} <- texto_obligatorio(nombre, :nombre_vacio),
         {:ok, edad} <- validar_edad(edad),
         {:ok, zona} <- texto_obligatorio(zona, :zona_vacia),
         {:ok, estado} <- validar_estado(estado),
         {:ok, personas} <- listar(),
         :ok <- documento_libre(personas, documento),
         {:ok, persona} <-
           Epicenter.Persona.nuevo(documento, nil, nombre, edad, zona, estado, nil, [
             entrada_historial(estado, por)
           ]) do
      Epicenter.Persistencia.guardar_personas([persona | personas])
      {:ok, persona}
    end
  end

  @doc "Busca una persona por su documento o dato de referencia (comando `find_person`)."
  def obtener_por_documento(documento) do
    with {:ok, documento} <- texto_obligatorio(documento, :documento_vacio),
         {:ok, personas} <- listar() do
      buscar_por_documento(personas, documento)
    end
  end

  @doc """
  Busca personas por nombre, documento, zona o estado, solos o combinados.

  Filtros (lista de claves o mapa, con claves átomo o texto):
    - `:texto`: parte del nombre o del documento (sin importar mayúsculas ni tildes).
    - `:nombre`: parte del nombre.
    - `:documento`: documento exacto.
    - `:zona`: código de la zona.
    - `:estado`: átomo o texto.

  Un valor `nil` o vacío se ignora, igual que cuando el formulario deja un campo
  en blanco. Devuelve `{:ok, personas}` o `{:error, motivo}`: `:filtro_invalido`,
  `:estado_invalido` o `:filtros_invalidos`.
  """
  def buscar(filtros \\ [])

  def buscar(filtros) when is_list(filtros) or is_map(filtros) do
    with {:ok, filtros} <- normalizar_filtros(filtros),
         {:ok, personas} <- listar() do
      {:ok, Enum.filter(personas, &cumple_filtros?(&1, filtros))}
    end
  end

  def buscar(_filtros), do: {:error, :filtros_invalidos}

  @doc """
  Cambia el estado de una persona (comando `update_person`) y agrega el cambio al
  historial con la fecha y quién lo hizo.

  Devuelve `{:ok, persona}` o `{:error, motivo}`: `"Persona no encontrada"`,
  `:estado_invalido`, `:transicion_invalida` o `:ya_reunificada`.
  """
  def cambiar_estado(documento, nuevo_estado, por \\ "sistema") do
    with {:ok, documento} <- texto_obligatorio(documento, :documento_vacio),
         {:ok, personas} <- listar(),
         {:ok, persona} <- buscar_por_documento(personas, documento),
         {:ok, estado} <- validar_estado(nuevo_estado),
         :ok <- validar_transicion(persona.estado, estado) do
      actualizada = %{
        persona
        | estado: estado,
          historial: (persona.historial || []) ++ [entrada_historial(estado, por)]
      }

      Epicenter.Persistencia.guardar_personas(
        Enum.map(personas, fn existente ->
          if existente.id == actualizada.id, do: actualizada, else: existente
        end)
      )

      {:ok, actualizada}
    end
  end

  @doc "Historial de cambios de estado de una persona, del más antiguo al más reciente."
  def historial(documento) do
    with {:ok, persona} <- obtener_por_documento(documento) do
      {:ok, persona.historial || []}
    end
  end

  defp buscar_por_documento(personas, documento) do
    case Enum.find(personas, &(&1.documento == documento)) do
      nil -> {:error, "Persona no encontrada"}
      persona -> {:ok, persona}
    end
  end

  defp documento_libre(personas, documento) do
    if Enum.any?(personas, &(&1.documento == documento)),
      do: {:error, :documento_duplicado},
      else: :ok
  end

  defp entrada_historial(estado, por),
    do: %{fecha: Utilidad.generar_fecha_actual(), estado: estado, por: por}

  # --- Validaciones ---

  defp texto_obligatorio(valor, motivo) when is_binary(valor) do
    case String.trim(valor) do
      "" -> {:error, motivo}
      texto -> {:ok, texto}
    end
  end

  defp texto_obligatorio(_valor, motivo), do: {:error, motivo}

  defp validar_edad(edad) when is_integer(edad) and edad in 0..120, do: {:ok, edad}

  defp validar_edad(edad) when is_binary(edad) do
    case Integer.parse(String.trim(edad)) do
      {numero, ""} -> validar_edad(numero)
      _otro -> {:error, :edad_invalida}
    end
  end

  defp validar_edad(_edad), do: {:error, :edad_invalida}

  defp validar_estado(estado) when is_atom(estado) or is_binary(estado) do
    texto = estado |> to_string() |> String.trim()

    case Enum.find(Epicenter.Persona.estados(), &(Atom.to_string(&1) == texto)) do
      nil -> {:error, :estado_invalido}
      valido -> {:ok, valido}
    end
  end

  defp validar_estado(_estado), do: {:error, :estado_invalido}

  defp validar_transicion(:reunificada, _nuevo), do: {:error, :ya_reunificada}

  defp validar_transicion(actual, nuevo) do
    if nuevo in Map.get(@transiciones, actual || :sin_informacion, []),
      do: :ok,
      else: {:error, :transicion_invalida}
  end

  # --- Búsqueda ---

  defp normalizar_filtros(filtros) do
    Enum.reduce_while(filtros, {:ok, []}, fn {clave, valor}, {:ok, normalizados} ->
      case normalizar_filtro(clave, valor) do
        :omitir -> {:cont, {:ok, normalizados}}
        {:ok, filtro} -> {:cont, {:ok, [filtro | normalizados]}}
        {:error, _motivo} = error -> {:halt, error}
      end
    end)
  end

  defp normalizar_filtro(clave, valor) do
    case Enum.find(@filtros_busqueda, &(&1 == clave or Atom.to_string(&1) == clave)) do
      nil -> {:error, :filtro_invalido}
      campo -> valor_filtro(campo, valor)
    end
  end

  defp valor_filtro(_campo, nil), do: :omitir

  defp valor_filtro(campo, valor) when is_binary(valor) do
    case String.trim(valor) do
      "" -> :omitir
      texto -> valor_filtro_texto(campo, texto)
    end
  end

  defp valor_filtro(:estado, valor) when is_atom(valor), do: valor_filtro_texto(:estado, valor)
  defp valor_filtro(_campo, _valor), do: {:error, :filtro_invalido}

  defp valor_filtro_texto(:estado, valor) do
    with {:ok, estado} <- validar_estado(valor), do: {:ok, {:estado, estado}}
  end

  defp valor_filtro_texto(campo, texto) when campo in [:texto, :nombre],
    do: {:ok, {campo, normalizar_texto(texto)}}

  defp valor_filtro_texto(campo, texto), do: {:ok, {campo, texto}}

  defp cumple_filtros?(persona, filtros), do: Enum.all?(filtros, &cumple_filtro?(persona, &1))

  defp cumple_filtro?(persona, {:texto, texto}),
    do: contiene?(persona.nombre, texto) or contiene?(persona.documento, texto)

  defp cumple_filtro?(persona, {:nombre, texto}), do: contiene?(persona.nombre, texto)
  defp cumple_filtro?(persona, {:documento, documento}), do: persona.documento == documento
  defp cumple_filtro?(persona, {:zona, zona}), do: persona.codigo_zona == zona
  defp cumple_filtro?(persona, {:estado, estado}), do: persona.estado == estado

  defp contiene?(texto, buscado), do: texto |> normalizar_texto() |> String.contains?(buscado)

  # Minúsculas y sin tildes: "Andrés" se encuentra buscando "andres".
  defp normalizar_texto(texto) when is_binary(texto) do
    texto
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
  end

  defp normalizar_texto(_otro), do: ""

  defp buscar_persona(personas, id) do
    case Enum.find(personas, &(&1.id == id)) do
      nil -> {:error, "Persona no encontrada"}
      persona -> {:ok, persona}
    end
  end
end
