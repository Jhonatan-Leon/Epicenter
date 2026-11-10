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

  defp buscar_persona(personas, id) do
    case Enum.find(personas, &(&1.id == id)) do
      nil -> {:error, "Persona no encontrada"}
      persona -> {:ok, persona}
    end
  end
end
