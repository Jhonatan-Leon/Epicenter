defmodule Epicenter.GestorNecesidad do
  def listar, do: Epicenter.Persistencia.cargar_necesidades()

  def registro(codigo_zona, reportador_por) do
    with {:ok, necesidad} <- Epicenter.Necesidad.nuevo(codigo_zona, reportador_por),
         {:ok, necesidad} <- crear(necesidad) do
      {:ok, necesidad}
    end
  end

  def registro(
        codigo_zona,
        reportador_por,
        tipo,
        descripcion,
        cantidad,
        prioridad,
        estado,
        destino
      ) do
    with {:ok, necesidad} <-
           Epicenter.Necesidad.nuevo(
             codigo_zona,
             reportador_por,
             tipo,
             descripcion,
             cantidad,
             prioridad,
             estado,
             destino
           ),
         {:ok, necesidad} <- crear(necesidad) do
      {:ok, necesidad}
    end
  end

  def completar_informacion(id, tipo, descripcion, cantidad, prioridad, estado, destino) do
    with {:ok, necesidades} <- listar(),
         {:ok, necesidad} <- buscar_necesidad(necesidades, id),
         {:ok, necesidad_actualizada} <-
           Epicenter.Necesidad.completar_necesidad(
             necesidad,
             tipo,
             descripcion,
             cantidad,
             prioridad,
             estado,
             destino
           ) do
      necesidades_actualizadas =
        Enum.map(necesidades, fn existente ->
          if existente.id == id, do: necesidad_actualizada, else: existente
        end)

      Epicenter.Persistencia.guardar_necesidades(necesidades_actualizadas)
      {:ok, necesidad_actualizada}
    end
  end

  def obtener(id) do
    with {:ok, necesidades} <- listar() do
      case Enum.find(necesidades, &(&1.id == id)) do
        nil -> {:error, "Necesidad no encontrada"}
        necesidad -> {:ok, necesidad}
      end
    end
  end

  def crear(%Epicenter.Necesidad{} = necesidad) do
    with {:ok, necesidades} <- listar() do
      if Enum.any?(necesidades, &(&1.id == necesidad.id)) do
        {:error, "La necesidad ya existe"}
      else
        Epicenter.Persistencia.guardar_necesidades([necesidad | necesidades])
        {:ok, necesidad}
      end
    end
  end

  def crear(_), do: {:error, "La necesidad no es válida"}

  def actualizar(id, %Epicenter.Necesidad{id: id} = necesidad) do
    with {:ok, necesidades} <- listar() do
      if Enum.any?(necesidades, &(&1.id == id)) do
        Epicenter.Persistencia.guardar_necesidades(
          Enum.map(necesidades, fn existente ->
            if existente.id == id, do: necesidad, else: existente
          end)
        )

        {:ok, necesidad}
      else
        {:error, "Necesidad no encontrada"}
      end
    end
  end

  def actualizar(_id, _necesidad), do: {:error, "La necesidad no es válida"}

  def eliminar(id) do
    with {:ok, necesidades} <- listar() do
      case Enum.find(necesidades, &(&1.id == id)) do
        nil ->
          {:error, "Necesidad no encontrada"}

        necesidad ->
          Epicenter.Persistencia.guardar_necesidades(Enum.reject(necesidades, &(&1.id == id)))
          {:ok, necesidad}
      end
    end
  end

  defp buscar_necesidad(necesidades, id) do
    case Enum.find(necesidades, &(&1.id == id)) do
      nil -> {:error, "Necesidad no encontrada"}
      necesidad -> {:ok, necesidad}
    end
  end
end
