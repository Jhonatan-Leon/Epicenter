defmodule Epicenter.GestorHistorial do
  def listar, do: Epicenter.Persistencia.cargar_historiales()

  def registro(id_inventario, usuario, id_necesidad, codigo_destino) do
    with {:ok, historial} <-
           Epicenter.Historial.nuevo(id_inventario, usuario, id_necesidad, codigo_destino),
         {:ok, historial} <- crear(historial) do
      {:ok, historial}
    end
  end

  def registro(id_inventario, usuario, id_necesidad, codigo_destino, tipo, cantidad, fecha) do
    with {:ok, historial} <-
           Epicenter.Historial.nuevo(
             id_inventario,
             usuario,
             id_necesidad,
             codigo_destino,
             tipo,
             cantidad,
             fecha
           ),
         {:ok, historial} <- crear(historial) do
      {:ok, historial}
    end
  end

  def completar_informacion(id, tipo, cantidad, fecha) do
    with {:ok, historiales} <- listar(),
         {:ok, historial} <- buscar_historial(historiales, id),
         {:ok, historial_actualizado} <-
           Epicenter.Historial.completar_historial(historial, tipo, cantidad, fecha) do
      historiales_actualizados =
        Enum.map(historiales, fn existente ->
          if existente.id == id, do: historial_actualizado, else: existente
        end)

      Epicenter.Persistencia.guardar_historiales(historiales_actualizados)
      {:ok, historial_actualizado}
    end
  end

  def obtener(id) do
    with {:ok, historiales} <- listar() do
      case Enum.find(historiales, &(&1.id == id)) do
        nil -> {:error, "Historial no encontrado"}
        historial -> {:ok, historial}
      end
    end
  end

  def crear(%Epicenter.Historial{} = historial) do
    with {:ok, historiales} <- listar() do
      if Enum.any?(historiales, &(&1.id == historial.id)) do
        {:error, "El historial ya existe"}
      else
        Epicenter.Persistencia.guardar_historiales([historial | historiales])
        {:ok, historial}
      end
    end
  end

  def crear(_), do: {:error, "El historial no es válido"}

  def actualizar(id, %Epicenter.Historial{id: id} = historial) do
    with {:ok, historiales} <- listar() do
      if Enum.any?(historiales, &(&1.id == id)) do
        Epicenter.Persistencia.guardar_historiales(
          Enum.map(historiales, fn existente ->
            if existente.id == id, do: historial, else: existente
          end)
        )

        {:ok, historial}
      else
        {:error, "Historial no encontrado"}
      end
    end
  end

  def actualizar(_id, _historial), do: {:error, "El historial no es válido"}

  def eliminar(id) do
    with {:ok, historiales} <- listar() do
      case Enum.find(historiales, &(&1.id == id)) do
        nil ->
          {:error, "Historial no encontrado"}

        historial ->
          Epicenter.Persistencia.guardar_historiales(Enum.reject(historiales, &(&1.id == id)))
          {:ok, historial}
      end
    end
  end

  defp buscar_historial(historiales, id) do
    case Enum.find(historiales, &(&1.id == id)) do
      nil -> {:error, "Historial no encontrado"}
      historial -> {:ok, historial}
    end
  end
end
